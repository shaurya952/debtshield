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
    /// Average monthly food spend for all U.S. households (BLS). Food has no
    /// county or state dimension in the data, so this national figure is the
    /// "across the U.S." row for food, alongside the income-based typical.
    let nationalFood: Double
    /// Average monthly transportation spend for all U.S. households (BLS CE).
    let nationalTransportation: Double
    /// Average monthly personal/lifestyle spend for all U.S. households — BLS CE
    /// apparel + entertainment + personal care combined.
    let nationalPersonal: Double
    /// Average monthly water & public-services bill for all U.S. households (BLS CE).
    let nationalWater: Double
    /// Average monthly home upkeep for a typical U.S. homeowner — BLS CE property
    /// tax + maintenance/repairs/insurance/other. A homeowner figure, because
    /// renters carry almost none of this.
    let nationalHomeUpkeep: Double
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

    /// U.S. median gross rent, monthly — Census ACS 5-year, 2019–2023, the same
    /// basis as the county file. An official published figure, deliberately NOT
    /// an unweighted mean of the county medians: most counties are rural and
    /// cheap, so that mean (~$938) badly understates the real national typical.
    static let officialNationalRent: Double = 1348

    /// Average food spend for all U.S. consumer units — BLS Consumer Expenditure
    /// Survey 2023 (released 2024): $9,985/year, i.e. about $832/month. An
    /// official published all-households figure, the food analogue of
    /// `officialNationalRent`.
    static let officialNationalFoodMonthly: Double = 9985.0 / 12

    /// Average transportation spend for all U.S. consumer units — BLS Consumer
    /// Expenditure Survey 2023: $13,174/year, about $1,098/month. Covers vehicle
    /// purchase/finance, gas, insurance, maintenance, and public transit.
    static let officialNationalTransportationMonthly: Double = 13174.0 / 12

    /// Average personal/lifestyle spend for all U.S. consumer units — BLS
    /// Consumer Expenditure Survey 2023, summing apparel & services ($2,041),
    /// entertainment ($3,635), and personal care products & services ($927) =
    /// $6,603/year, about $550/month.
    static let officialNationalPersonalMonthly: Double = (2041.0 + 3635.0 + 927.0) / 12

    /// Average water & other public-services bill for all U.S. consumer units —
    /// BLS Consumer Expenditure Survey 2023: $780/year, about $65/month.
    static let officialNationalWaterMonthly: Double = 780.0 / 12

    /// Average home upkeep for a typical U.S. homeowner — BLS Consumer
    /// Expenditure Survey 2023, home-owner tenure: property taxes ($4,079) plus
    /// maintenance, repairs, insurance & other expenses ($3,974) = $8,053/year,
    /// about $671/month. A homeowner figure, since renters carry almost none.
    static let officialNationalHomeUpkeepMonthly: Double = (4079.0 + 3974.0) / 12

    static func load(bundle: Bundle = .main) -> Benchmarks {
        let energy = loadEnergy(bundle: bundle)
        let bills = Array(energy.byState.values)
        let nationalEnergy = bills.isEmpty ? 0 : bills.reduce(0, +) / Double(bills.count)
        return Benchmarks(
            energy: energy,
            food: loadFood(bundle: bundle),
            nationalRent: officialNationalRent,
            nationalEnergy: nationalEnergy,
            nationalFood: officialNationalFoodMonthly,
            nationalTransportation: officialNationalTransportationMonthly,
            nationalPersonal: officialNationalPersonalMonthly,
            nationalWater: officialNationalWaterMonthly,
            nationalHomeUpkeep: officialNationalHomeUpkeepMonthly
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
        nationalEnergy: 137,
        nationalFood: 832,
        nationalTransportation: 1098,
        nationalPersonal: 550,
        nationalWater: 65,
        nationalHomeUpkeep: 671
    )
}
#endif
