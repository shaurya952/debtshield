import Foundation

// MARK: - Errors

/// Load failures, phrased for a person rather than a stack trace.
///
/// Every case carries a short `title`, a `message` in plain language, and a
/// `recoverySuggestion` for the developer-facing detail. The UI shows title and
/// message; the detail sits behind a disclosure so it never shouts at a user.
enum DataError: LocalizedError, Equatable {
    case fileMissing(name: String)
    case unreadable(name: String, underlying: String)
    case emptyFile(name: String)
    case missingColumns([String])
    case noUsableRows

    var title: String {
        switch self {
        case .fileMissing: return "Data file not found"
        case .unreadable: return "Data file could not be read"
        case .emptyFile: return "Data file is empty"
        case .missingColumns: return "Data file is missing information"
        case .noUsableRows: return "No county data found"
        }
    }

    /// Shown to the user. No jargon, no file paths in the first sentence.
    var message: String {
        switch self {
        case .fileMissing:
            return "DebtShield could not find its built-in comparison data. Reinstalling the app usually fixes this."
        case .unreadable:
            return "The built-in county dataset could not be opened. It may have been damaged. Reinstalling the app usually fixes this."
        case .emptyFile:
            return "The built-in county dataset contains no information."
        case .missingColumns(let columns):
            let list = ListFormatter.localizedString(byJoining: columns)
            return "The comparison data is missing some information: \(list)."
        case .noUsableRows:
            return "The dataset loaded, but none of its rows contained enough information to score a county."
        }
    }

    /// Developer-facing detail, kept out of the primary message.
    var technicalDetail: String? {
        switch self {
        case .fileMissing(let name):
            return "\(name) was not found in Bundle.main. Check Target ▸ Build Phases ▸ Copy Bundle Resources."
        case .unreadable(let name, let underlying):
            return "\(name): \(underlying)"
        case .emptyFile(let name):
            return "\(name) parsed to zero rows."
        case .missingColumns(let columns):
            return "Missing required columns: \(columns.joined(separator: ", "))"
        case .noUsableRows:
            return "All rows failed validation (non-numeric or blank required fields)."
        }
    }

    var errorDescription: String? { message }
}

// MARK: - Loader

/// Loads and parses the bundled county dataset.
///
/// Users never upload anything. The CSV ships inside the app bundle and is read
/// with `Bundle.main.url(forResource:withExtension:)`.
struct CSVLoader {

    static let resourceName = "real_county_data"
    static let resourceExtension = "csv"

    /// Columns the app cannot score without.
    static let requiredColumns = [
        "state", "county", "acs_median_household_income",
        "acs_rent_burden_pct", "acs_poverty_rate", "bls_unemployment_rate"
    ]

    let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    // MARK: Entry point

    func loadDataset() throws -> Dataset {
        guard let url = bundle.url(forResource: Self.resourceName, withExtension: Self.resourceExtension) else {
            throw DataError.fileMissing(name: "\(Self.resourceName).\(Self.resourceExtension)")
        }

        let text: String
        do {
            text = try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw DataError.unreadable(
                name: "\(Self.resourceName).\(Self.resourceExtension)",
                underlying: error.localizedDescription
            )
        }

        let table = try Self.parseTable(text, fileName: "\(Self.resourceName).\(Self.resourceExtension)")

        let missing = Self.requiredColumns.filter { table.columnIndex[$0] == nil }
        guard missing.isEmpty else { throw DataError.missingColumns(missing) }

        var records = Self.buildRecords(from: table)
        guard !records.isEmpty else { throw DataError.noUsableRows }

        Self.fillMissingWithMedians(&records)

        let capabilities = Self.capabilities(for: table.columnIndex)
        let scored = RiskScoring.scoreAll(records, capabilities: capabilities)

        return Dataset(
            counties: scored,
            capabilities: capabilities,
            sourceDescription: "U.S. Census ACS 5-Year estimates · \(scored.count.formatted(.number)) counties",
            benchmarks: Self.benchmarks(for: scored, capabilities: capabilities)
        )
    }

    // MARK: Parsing

    struct Table {
        var columnIndex: [String: Int]
        var rows: [[String]]
    }

    /// Minimal RFC-4180 parser: handles quoted fields and embedded commas.
    /// The bundled file contains no quoted fields, but county names elsewhere
    /// ("Doña Ana County, NM" style exports) commonly do.
    static func parseTable(_ text: String, fileName: String) throws -> Table {
        var lines = text.components(separatedBy: .newlines)
        lines.removeAll { $0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard let headerLine = lines.first else { throw DataError.emptyFile(name: fileName) }

        let header = splitCSVLine(headerLine).map {
            $0.trimmingCharacters(in: .whitespaces).lowercased()
        }
        var columnIndex: [String: Int] = [:]
        for (i, name) in header.enumerated() where columnIndex[name] == nil {
            columnIndex[name] = i
        }

        let rows = lines.dropFirst().map { splitCSVLine($0) }
        guard !rows.isEmpty else { throw DataError.emptyFile(name: fileName) }
        return Table(columnIndex: columnIndex, rows: Array(rows))
    }

    static func splitCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var insideQuotes = false
        var iterator = line.makeIterator()

        while let character = iterator.next() {
            if character == "\"" {
                insideQuotes.toggle()
            } else if character == "," && !insideQuotes {
                fields.append(current)
                current = ""
            } else {
                current.append(character)
            }
        }
        fields.append(current)
        return fields.map { $0.trimmingCharacters(in: .whitespaces) }
    }

    // MARK: Record construction

    static func buildRecords(from table: Table) -> [CountyRecord] {
        func field(_ row: [String], _ name: String) -> String? {
            guard let i = table.columnIndex[name], i < row.count else { return nil }
            let value = row[i]
            return value.isEmpty ? nil : value
        }
        func number(_ row: [String], _ name: String) -> Double? {
            guard let raw = field(row, name) else { return nil }
            return Double(raw)
        }

        return table.rows.compactMap { row -> CountyRecord? in
            // Identity is the only hard requirement. A county missing some
            // indicators is kept and reported as unscored — dropping it would
            // silently remove a real place from the app, which is exactly the
            // bug that lost Esmeralda County, Nevada and Kenedy County, Texas
            // from the original dataset. Rows with no state or county name at
            // all are the blank trailing rows pandas exports leave behind.
            guard let state = field(row, "state"),
                  let county = field(row, "county")
            else { return nil }

            // FIPS is the stable identity. Fall back to the name if absent so
            // Identifiable never collides.
            let fips = field(row, "fips") ?? "\(state)-\(county)"

            return CountyRecord(
                fips: fips,
                state: state,
                county: county,
                year: number(row, "year").map { Int($0) },
                medianHouseholdIncome: number(row, "acs_median_household_income"),
                medianGrossRent: number(row, "acs_median_gross_rent"),
                rentBurdenPct: number(row, "acs_rent_burden_pct"),
                povertyRate: number(row, "acs_poverty_rate"),
                unemploymentRate: number(row, "bls_unemployment_rate"),
                evictionFilingRate: number(row, "eviction_filing_rate"),
                jobGrowthPct: number(row, "bls_job_growth_pct"),
                avgHouseholdDebt: number(row, "scf_avg_household_debt"),
                debtToIncomeRatio: number(row, "scf_debt_to_income_ratio"),
                creditCardDelinquencyRate: number(row, "nyfed_credit_card_delinquency_rate"),
                energyBurdenPct: number(row, "doe_total_energy_burden_pct"),
                lowIncomeLowAccessPct: number(row, "usda_low_income_low_access_pct")
            )
        }
    }

    /// Replicates the median fill in the Python `clean_dataframe()`.
    ///
    /// In the bundled dataset this affects exactly 9 counties, all missing
    /// `acs_median_gross_rent`. Without it those counties would score a rent
    /// ratio of 0 and read as artificially safe.
    static func fillMissingWithMedians(_ records: inout [CountyRecord]) {
        let knownRents = records.compactMap(\.medianGrossRent)
        guard knownRents.count < records.count, let median = median(of: knownRents) else { return }
        for i in records.indices where records[i].medianGrossRent == nil {
            records[i].medianGrossRent = median
        }
    }

    /// Matches pandas' `Series.median()`: even counts average the middle pair.
    static func median(of values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let mid = sorted.count / 2
        if sorted.count.isMultiple(of: 2) {
            return (sorted[mid - 1] + sorted[mid]) / 2
        }
        return sorted[mid]
    }

    // MARK: Benchmarks

    /// National distribution per measured driver, built from scored counties
    /// only so unscored counties cannot skew the percentiles.
    static func benchmarks(
        for counties: [ScoredCounty],
        capabilities: DatasetCapabilities
    ) -> [DriverKind: DriverBenchmark] {
        let scored = counties.filter(\.isScored)
        var result: [DriverKind: DriverBenchmark] = [:]
        for kind in capabilities.measuredDrivers {
            let scores = scored.compactMap { $0.driver(kind)?.score }
            guard !scores.isEmpty else { continue }
            result[kind] = DriverBenchmark(scores: scores)
        }
        return result
    }

    // MARK: Capabilities

    static func capabilities(for columnIndex: [String: Int]) -> DatasetCapabilities {
        let has = { (name: String) in columnIndex[name] != nil }
        return DatasetCapabilities(
            hasDebtSources: has("scf_avg_household_debt")
                || has("scf_debt_to_income_ratio")
                || has("nyfed_credit_card_delinquency_rate"),
            hasEnergySource: has("doe_total_energy_burden_pct"),
            hasFoodSource: has("usda_low_income_low_access_pct"),
            hasEvictionSource: has("eviction_filing_rate"),
            hasJobGrowthSource: has("bls_job_growth_pct")
        )
    }
}
