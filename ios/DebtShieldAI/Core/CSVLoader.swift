import Foundation

// MARK: - Errors

/// Load failures, phrased for a person rather than a stack trace.
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

    var message: String {
        switch self {
        case .fileMissing:
            return "Headroom could not find its built-in comparison data. Reinstalling the app usually fixes this."
        case .unreadable:
            return "The built-in comparison data could not be opened. It may have been damaged. Reinstalling the app usually fixes this."
        case .emptyFile:
            return "The built-in comparison data contains no information."
        case .missingColumns(let columns):
            let list = ListFormatter.localizedString(byJoining: columns)
            return "The comparison data is missing some information: \(list)."
        case .noUsableRows:
            return "The data loaded, but none of its rows contained a usable place."
        }
    }

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
            return "All rows failed validation (no state or county name)."
        }
    }

    var errorDescription: String? { message }
}

// MARK: - Loader

/// Loads and parses the bundled county file. Users never upload anything — the
/// CSV ships inside the app bundle. It's read purely for the comparison layer:
/// typical rent and income per place.
struct CSVLoader {

    static let resourceName = "real_county_data"
    static let resourceExtension = "csv"

    /// The only columns the comparison layer needs to identify a place.
    static let requiredColumns = ["state", "county"]

    let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

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

        Self.fillMissingRentWithMedian(&records)

        return Dataset(counties: records.map { ScoredCounty(record: $0) },
                       metros: Self.loadMetros(bundle: bundle))
    }

    /// Load the population-weighted metro areas (`metro_data.csv`). Each becomes a
    /// `ScoredCounty` with FIPS `"M" + cbsa`. Missing/failed load simply yields no
    /// metros — the county layer still works — so this can never break startup.
    static func loadMetros(bundle: Bundle) -> [ScoredCounty] {
        guard let url = bundle.url(forResource: "metro_data", withExtension: "csv"),
              let text = try? String(contentsOf: url, encoding: .utf8),
              let table = try? parseTable(text, fileName: "metro_data.csv")
        else { return [] }
        func field(_ row: [String], _ name: String) -> String? {
            guard let i = table.columnIndex[name], i < row.count, !row[i].isEmpty else { return nil }
            return row[i]
        }
        return table.rows.compactMap { row -> ScoredCounty? in
            guard let cbsa = field(row, "cbsa"), let name = field(row, "metro"),
                  let state = field(row, "state") else { return nil }
            let record = CountyRecord(
                fips: "M\(cbsa)",
                state: state,
                county: name,
                medianHouseholdIncome: field(row, "median_household_income").flatMap(Double.init),
                medianGrossRent: field(row, "median_gross_rent").flatMap(Double.init),
                displayOverride: name
            )
            return ScoredCounty(record: record)
        }
    }

    // MARK: Parsing

    struct Table {
        var columnIndex: [String: Int]
        var rows: [[String]]
    }

    /// Minimal RFC-4180 parser: handles quoted fields and embedded commas.
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
            guard let state = field(row, "state"),
                  let county = field(row, "county")
            else { return nil }

            let fips = field(row, "fips") ?? "\(state)-\(county)"

            return CountyRecord(
                fips: fips,
                state: state,
                county: county,
                medianHouseholdIncome: number(row, "acs_median_household_income"),
                medianGrossRent: number(row, "acs_median_gross_rent")
            )
        }
    }

    /// Fills the handful of counties missing a rent figure with the national
    /// median, so the rent comparison still has something to show for them.
    static func fillMissingRentWithMedian(_ records: inout [CountyRecord]) {
        let knownRents = records.compactMap(\.medianGrossRent)
        guard knownRents.count < records.count, let median = median(of: knownRents) else { return }
        for i in records.indices where records[i].medianGrossRent == nil {
            records[i].medianGrossRent = median
        }
    }

    static func median(of values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let mid = sorted.count / 2
        if sorted.count.isMultiple(of: 2) {
            return (sorted[mid - 1] + sorted[mid]) / 2
        }
        return sorted[mid]
    }
}
