import Foundation

/// Typical-cost reference data — what a person's own spending is measured
/// against. It ships inside the app and never leaves the device.
///
/// It carries three levels of "typical":
/// - **your area** — your county's rent, your state's energy bill
/// - **across the U.S.** — the national averages, computed from the same data
/// - **a guideline** — for debt, the common rule of thumb
///
/// Anything the data doesn't cover returns `nil`, and the app simply shows no
/// comparison rather than a guessed one.
struct Benchmarks: Equatable, Sendable {
    let energy: EnergyBenchmark
    let food: FoodBenchmark
    /// Average monthly rent across every U.S. county (Census).
    let nationalRent: Double
    /// Average monthly electricity bill across all states (EIA).
    let nationalEnergy: Double
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
    /// income falls in a band the data doesn't cover. Bands are keyed on annual
    /// income, so the monthly figure is annualised to find the band and the
    /// result divided back down.
    func typicalMonthly(forMonthlyIncome monthly: Double) -> Double? {
        let annual = monthly * 12
        let band = bands.first { annual >= $0.low && (($0.high == nil) || annual <= $0.high!) }
        guard let band else { return nil }
        return band.annual / 12
    }

    var bandCount: Int { bands.count }
}

// MARK: - Loading

/// Reads the comparison data from the bundle and computes the national
/// averages. Tiny work, so it's synchronous. Malformed or incomplete rows are
/// skipped, not fatal.
enum BenchmarksLoader {

    static func load(bundle: Bundle = .main) -> Benchmarks {
        let energy = loadEnergy(bundle: bundle)
        let bills = Array(energy.byState.values)
        let nationalEnergy = bills.isEmpty ? 0 : bills.reduce(0, +) / Double(bills.count)
        return Benchmarks(
            energy: energy,
            food: loadFood(bundle: bundle),
            nationalRent: loadNationalRent(bundle: bundle),
            nationalEnergy: nationalEnergy
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
            else { continue }
            let highRaw = row[1].trimmingCharacters(in: .whitespaces)
            let high = highRaw.isEmpty ? nil : Double(highRaw)
            bands.append(FoodBenchmark.Band(low: low, high: high, annual: annual))
        }
        return FoodBenchmark(bands: bands.sorted { $0.low < $1.low })
    }

    /// Average monthly rent across all counties, read straight from the bundled
    /// county file. A light single-column pass — no full parse needed.
    static func loadNationalRent(bundle: Bundle) -> Double {
        guard let url = bundle.url(forResource: "real_county_data", withExtension: "csv"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return 0 }

        let lines = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard let header = lines.first else { return 0 }
        let cols = header.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
        guard let rentIndex = cols.firstIndex(of: "acs_median_gross_rent") else { return 0 }

        var total = 0.0
        var count = 0
        for line in lines.dropFirst() {
            let fields = line.components(separatedBy: ",")
            guard rentIndex < fields.count,
                  let rent = Double(fields[rentIndex].trimmingCharacters(in: .whitespaces)) else { continue }
            total += rent
            count += 1
        }
        return count == 0 ? 0 : total / Double(count)
    }

    /// Split a bundled CSV into rows of fields, dropping the header and blanks.
    private static func rows(of resource: String, bundle: Bundle) -> [[String]] {
        guard let url = bundle.url(forResource: resource, withExtension: "csv"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return []
        }
        return text
            .components(separatedBy: .newlines)
            .dropFirst()
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
        ]),
        nationalRent: 1300,
        nationalEnergy: 137
    )
}
#endif
