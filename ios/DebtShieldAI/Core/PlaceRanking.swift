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
        /// keeps the person's current income. A later, occupation-aware phase will
        /// vary this *per place* from wage data; here it's one figure everywhere.
        var incomeOverride: Double?
        /// Only rank places that clear this much money left each month.
        var minMonthlyLeft: Double?
        /// Restrict to a single state (full name, matching the county file), for a
        /// "near me / this region" view.
        var stateFilter: String?
        /// How many places to return, best first.
        var limit: Int

        init(incomeOverride: Double? = nil,
             minMonthlyLeft: Double? = nil,
             stateFilter: String? = nil,
             limit: Int = 25) {
            self.incomeOverride = incomeOverride
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
        guard (options.incomeOverride ?? plan.monthlyIncome).map({ $0 > 0 }) == true else { return [] }

        var ranked: [RankedPlace] = []
        ranked.reserveCapacity(dataset.counties.count)

        for county in dataset.counties {
            if let state = options.stateFilter, county.state != state { continue }
            let stateEnergy = energy.typicalBill(inState: county.state)
            guard let outlook = AffordabilityEngine.outlook(
                current: plan,
                place: county,
                stateEnergy: stateEnergy,
                incomeOverride: options.incomeOverride
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
