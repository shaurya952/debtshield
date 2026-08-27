import Foundation

/// State-level rollup of the place ranking — the big-picture view.
///
/// People usually want to know *which states* stretch their money before they
/// pick a specific county. This groups the per-county results (`PlaceRankingEngine`)
/// by state and ranks the states by their **typical** county — the median
/// money-left-over, which is robust to one unusually cheap or pricey county. Each
/// ranked state also carries its single best county, so the list can preview
/// "and its best spot is…" and drill straight in.
///
/// Pure and synchronous, no SwiftUI — same testable shape as the other engines.
enum StateRankingEngine {

    struct RankedState: Identifiable, Equatable, Sendable {
        let state: String
        /// The typical (median) county's projected money-left-over — the sort key.
        let medianMonthlyLeft: Double
        /// The single county in this state that leaves the most room.
        let best: PlaceRankingEngine.RankedPlace
        /// How many of the state's ranked counties stay out of the red.
        let affordableCount: Int
        /// How many counties in the state had enough data to rank at all.
        let rankedCount: Int

        var id: String { state }
    }

    /// Rank the states for a plan. Reuses the county engine (so the math is
    /// identical), then rolls up. Deterministic: median for the score, state name
    /// as the tie-break, best-county already deterministic from the county engine.
    static func rank(plan: MoneyPlan,
                     in dataset: Dataset,
                     energy: EnergyBenchmark,
                     incomeOverride: Double? = nil) -> [RankedState] {
        // Rank every county (no limit) so the rollup sees the whole state.
        let places = PlaceRankingEngine.rank(
            plan: plan, in: dataset, energy: energy,
            options: PlaceRankingEngine.Options(incomeOverride: incomeOverride, limit: .max))

        let byState = Dictionary(grouping: places, by: { $0.county.state })

        var states: [RankedState] = []
        states.reserveCapacity(byState.count)
        for (state, group) in byState {
            // `group` is already in the engine's ranked order (most room first),
            // so its first element is the best county.
            guard let best = group.first else { continue }
            let median = medianMonthlyLeft(of: group)
            let affordable = group.reduce(into: 0) { if $1.monthlyLeft >= 0 { $0 += 1 } }
            states.append(RankedState(state: state,
                                      medianMonthlyLeft: median,
                                      best: best,
                                      affordableCount: affordable,
                                      rankedCount: group.count))
        }

        states.sort { a, b in
            a.medianMonthlyLeft != b.medianMonthlyLeft
                ? a.medianMonthlyLeft > b.medianMonthlyLeft
                : a.state < b.state
        }
        return states
    }

    /// Median of a group's money-left values. The group is ranked descending, so
    /// the middle element(s) are the median; for an even count, average the two.
    private static func medianMonthlyLeft(of group: [PlaceRankingEngine.RankedPlace]) -> Double {
        let values = group.map(\.monthlyLeft)   // already sorted high→low
        let n = values.count
        guard n > 0 else { return 0 }
        if n % 2 == 1 { return values[n / 2] }
        return (values[n / 2 - 1] + values[n / 2]) / 2
    }
}
