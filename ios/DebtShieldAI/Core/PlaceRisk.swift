import Foundation

/// The ranking's second axis: not just "how much room", but "how safe".
///
/// A place can look affordable on the month's averages yet be fragile once normal
/// ups and downs are simulated. This runs the same Monte Carlo engine on the
/// budget you'd have *living there* and reads the odds of running short over the
/// year — so a cheap-but-tight county is flagged, not hidden.
enum PlaceRiskEngine {

    /// Fewer runs than the Home-screen forecast, because this is computed for many
    /// places at once; still seeded (42) so a place's risk never flickers between
    /// views. 300 runs keeps the 95% error band on a mid-range probability to a
    /// few points — plenty for a low / watch / high band.
    static let runs = 300
    static let seed: UInt64 = 42

    /// Odds (0…1) the running balance goes negative at some point within 12 months
    /// on the projected budget. `nil` when the plan can't be simulated.
    static func shortfallOdds(for projected: MoneyPlan) -> Double? {
        MonteCarloEngine.simulate(plan: projected, history: [], runs: runs, seed: seed)?
            .probNegativeWithin12mo
    }

    /// Educational risk bands (see THRESHOLD_REGISTRY). Not universal truth — a
    /// named heuristic for turning a probability into a plain word.
    static let watchThreshold = 0.15
    static let highThreshold = 0.35

    enum Level: String, Sendable, Equatable, CaseIterable {
        case low, watch, high

        /// Plain, non-alarming words.
        var word: String {
            switch self {
            case .low: return "Low risk"
            case .watch: return "Some risk"
            case .high: return "Higher risk"
            }
        }
    }

    static func level(forOdds odds: Double) -> Level {
        if odds >= highThreshold { return .high }
        if odds >= watchThreshold { return .watch }
        return .low
    }

    /// Convenience: simulate and band in one call. `nil` if not simulatable.
    static func level(for projected: MoneyPlan) -> Level? {
        shortfallOdds(for: projected).map(level(forOdds:))
    }
}
