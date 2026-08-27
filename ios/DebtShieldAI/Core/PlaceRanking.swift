import Foundation

/// The relocation-ranking engine — the app's hero.
///
/// `AffordabilityEngine` already answers "how would my money look in *one* place".
/// This runs that same deterministic math across **every** county in the dataset
/// and ranks them, so the person doesn't have to already know where to look. The
/// output is the ordered list behind the Places screen: where your real numbers
/// would leave you the most breathing room.
///
/// Pure and synchronous with **no SwiftUI import**, so it stays headlessly
/// testable and can be run off the main thread by callers (like Monte Carlo).
/// Nothing here is a guess — every figure comes from the bundled Census/EIA data
/// and the person's own budget, on the device.
enum PlaceRankingEngine {

    /// One place in the ranking: the county and the full affordability outlook for
    /// living there, kept together so the list can rank and the detail screen can
    /// show the side-by-side without recomputing.
    struct RankedPlace: Identifiable, Equatable, Sendable {
        let county: ScoredCounty
        let outlook: MoveOutlook

        var id: String { county.id }
        /// Projected money left over each month living here — the primary sort key.
        var monthlyLeft: Double { outlook.projectedLeft }
    }

    /// How to shape the ranking. All optional, so the default is "rank the whole
    /// country by breathing room on my current income."
    struct Options: Equatable, Sendable {
        /// Model a different salary (e.g. a new job) applied to every place. `nil`
        /// keeps the person's current income.
        var incomeOverride: Double?
        /// The "same job, new place" income: a full state name → monthly take-home
        /// map (an occupation's local pay). When set, each county uses its state's
        /// figure, and a county whose state isn't in the map is skipped — the job
        /// isn't reported there, so it isn't guessed. Takes precedence over
        /// `incomeOverride`.
        var incomeByState: [String: Double]?
        /// Only rank places that clear this much money left each month.
        var minMonthlyLeft: Double?
        /// Restrict to a single state (full name, matching the county file), for a
        /// "near me / this region" view.
        var stateFilter: String?
        /// How many places to return, best first.
        var limit: Int

        init(incomeOverride: Double? = nil,
             incomeByState: [String: Double]? = nil,
             minMonthlyLeft: Double? = nil,
             stateFilter: String? = nil,
             limit: Int = 25) {
            self.incomeOverride = incomeOverride
            self.incomeByState = incomeByState
            self.minMonthlyLeft = minMonthlyLeft
            self.stateFilter = stateFilter
            self.limit = limit
        }
    }

    /// Rank places for a plan. A county appears only when it has the data the
    /// outlook needs (a typical rent) *and* the person has an income to measure
    /// against — otherwise it's silently skipped, never guessed.
    ///
    /// Deterministic: same inputs always produce the same order (ties break by
    /// FIPS), so the list never reshuffles between runs.
    static func rank(plan: MoneyPlan,
                     in dataset: Dataset,
                     energy: EnergyBenchmark,
                     options: Options = Options()) -> [RankedPlace] {
        // There must be *some* income source: a per-state map, a flat override, or
        // the person's own income.
        let hasIncome = (options.incomeByState?.isEmpty == false)
            || (options.incomeOverride ?? plan.monthlyIncome).map({ $0 > 0 }) == true
        guard hasIncome else { return [] }

        var ranked: [RankedPlace] = []
        ranked.reserveCapacity(dataset.counties.count)

        for county in dataset.counties {
            if let state = options.stateFilter, county.state != state { continue }
            // Per-state occupation pay wins; a state the job doesn't report is skipped.
            let income: Double?
            if let byState = options.incomeByState {
                guard let local = byState[county.state] else { continue }
                income = local
            } else {
                income = options.incomeOverride
            }
            let stateEnergy = energy.typicalBill(inState: county.state)
            guard let outlook = AffordabilityEngine.outlook(
                current: plan,
                place: county,
                stateEnergy: stateEnergy,
                incomeOverride: income
            ) else { continue }
            if let floor = options.minMonthlyLeft, outlook.projectedLeft < floor { continue }
            ranked.append(RankedPlace(county: county, outlook: outlook))
        }

        // Most breathing room first; FIPS as a stable, deterministic tie-break.
        ranked.sort { a, b in
            a.monthlyLeft != b.monthlyLeft ? a.monthlyLeft > b.monthlyLeft : a.county.id < b.county.id
        }

        return options.limit < ranked.count ? Array(ranked.prefix(options.limit)) : ranked
    }
}
