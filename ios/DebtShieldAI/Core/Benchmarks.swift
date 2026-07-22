import Foundation

/// Typical-cost reference data, loaded from the bundled comparison CSVs.
///
/// These are the numbers a person's own spending is measured against — the
/// "comparison layer". Like the county data they ship inside the app and never
/// leave the device. Anything the files don't cover (a state with no row, an
/// income that falls in a gap) simply returns `nil`, and the app shows no
/// comparison rather than a guessed one.
struct Benchmarks: Equatable, Sendable {
    let energy: EnergyBenchmark
    let food: FoodBenchmark
}

/// Average monthly residential electricity bill, by state (EIA).
struct EnergyBenchmark: Equatable, Sendable {
    /// Full state name → average monthly bill in dollars. Full names because
    /// that's how the county data spells them, and the two are matched by name.
    let byState: [String: Double]

    func typicalBill(inState state: String) -> Double? {
        byState[state]
    }

    var stateCount: Int { byState.count }
}

/// Average annual food spending by income-before-taxes band (BLS Consumer
/// Expenditure Survey).
struct FoodBenchmark: Equatable, Sendable {
    struct Band: Equatable, Sendable {
        let low: Double
        /// `nil` for the open-ended top band ("$200,000 and over").
        let high: Double?
        let annual: Double
    }

    let bands: [Band]

    /// Typical monthly food spend for a given *monthly* income, or `nil` if the
    /// income falls in a band the data doesn't cover (e.g. the $50k–$70k gap in
    /// the current file). The bands are keyed on annual income, so the monthly
    /// figure is annualised to find the band and the result divided back down.
    func typicalMonthly(forMonthlyIncome monthly: Double) -> Double? {
        let annual = monthly * 12
        let band = bands.first { annual >= $0.low && (($0.high == nil) || annual <= $0.high!) }
        guard let band else { return nil }
        return band.annual / 12
    }

    var bandCount: Int { bands.count }
}

// MARK: - Loading

/// Reads the two comparison CSVs from the bundle. Tiny files, so this is
/// synchronous. Malformed or incomplete rows are skipped, not fatal — a partly
/// filled file still powers every comparison it can.
enum BenchmarksLoader {

    static func load(bundle: Bundle = .main) -> Benchmarks {
        Benchmarks(
            energy: loadEnergy(bundle: bundle),
            food: loadFood(bundle: bundle)
        )
    }

    static func loadEnergy(bundle: Bundle) -> EnergyBenchmark {
        var map: [String: Double] = [:]
        for row in rows(of: "energy_by_state", bundle: bundle) {
            guard row.count >= 2 else { continue }
            let state = row[0].trimmingCharacters(in: .whitespaces)
            guard !state.isEmpty, let bill = Double(row[1].trimmingCharacters(in: .whitespaces)) else { continue }
            map[state] = bill
        }
        return EnergyBenchmark(byState: map)
    }

    static func loadFood(bundle: Bundle) -> FoodBenchmark {
        var bands: [FoodBenchmark.Band] = []
        for row in rows(of: "food_by_income_band", bundle: bundle) {
            guard row.count >= 3,
                  let low = Double(row[0].trimmingCharacters(in: .whitespaces)),
                  let annual = Double(row[2].trimmingCharacters(in: .whitespaces))
            else { continue } // skips VERIFY / blank / header-mismatched rows
            let highRaw = row[1].trimmingCharacters(in: .whitespaces)
            let high = highRaw.isEmpty ? nil : Double(highRaw)
            bands.append(FoodBenchmark.Band(low: low, high: high, annual: annual))
        }
        return FoodBenchmark(bands: bands.sorted { $0.low < $1.low })
    }

    /// Split a bundled CSV into rows of fields, dropping the header and any
    /// blank lines. No quoted-field handling needed — these files have none.
    private static func rows(of resource: String, bundle: Bundle) -> [[String]] {
        guard let url = bundle.url(forResource: resource, withExtension: "csv"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return []
        }
        return text
            .components(separatedBy: .newlines)
            .dropFirst() // header
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .map { $0.components(separatedBy: ",") }
    }
}

#if DEBUG
extension Benchmarks {
    /// Small fixed sample for previews, so they don't depend on the bundle.
    static let previewSample = Benchmarks(
        energy: EnergyBenchmark(byState: ["Alabama": 173.50, "California": 160.86]),
        food: FoodBenchmark(bands: [
            .init(low: 0, high: 15000, annual: 5315),
            .init(low: 30000, high: 39999, annual: 6956),
            .init(low: 200000, high: nil, annual: 18453)
        ])
    )
}
#endif
