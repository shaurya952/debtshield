import Foundation
import Observation

/// A move goal the person is working toward — the one honest reason to reopen a
/// relocation tool month after month. It turns a one-time "where would my money go
/// furthest?" lookup into a trajectory: a target place, a rough moving fund, and
/// progress toward it. Like everything else it lives only in `UserDefaults`
/// (`debtshield.*`) and never leaves the phone.
struct MovePlan: Codable, Equatable, Sendable {
    /// FIPS of the target place — a county or a metro ("M" + CBSA).
    var targetFIPS: String
    var targetName: String
    /// The place's typical monthly rent, stored so the fund goal is stable even if
    /// the person hasn't loaded the place data yet.
    var targetRent: Double
    /// What they've set aside toward the move so far.
    var savedSoFar: Double = 0

    /// A rough moving-fund target: first + last month's rent plus a deposit and
    /// truck — about three months' rent, with a sensible floor. A **named
    /// heuristic** (see THRESHOLD_REGISTRY), shown as an estimate, never a quote.
    var fundGoal: Double { max(2_000, (targetRent * 3).rounded()) }

    /// 0…1 progress toward the fund goal.
    var progress: Double { fundGoal > 0 ? min(1, max(0, savedSoFar / fundGoal)) : 0 }
    var isFunded: Bool { savedSoFar >= fundGoal }
}

@MainActor
@Observable
final class MovePlanStore {
    static let defaultsKey = "debtshield.movePlan"

    private(set) var plan: MovePlan?
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.defaultsKey),
           let decoded = try? JSONDecoder().decode(MovePlan.self, from: data) {
            plan = decoded
        }
    }

    var hasPlan: Bool { plan != nil }
    func isTarget(_ fips: String) -> Bool { plan?.targetFIPS == fips }

    /// Set (or replace) the move goal for a place. Keeps the saved amount if the
    /// same place is re-set, so re-tapping doesn't wipe progress.
    func setTarget(fips: String, name: String, rent: Double) {
        let keepSaved = (plan?.targetFIPS == fips) ? (plan?.savedSoFar ?? 0) : 0
        plan = MovePlan(targetFIPS: fips, targetName: name, targetRent: rent, savedSoFar: keepSaved)
        persist()
        // Offer a gentle monthly nudge toward the goal (asks permission once; a no
        // just means no nudge).
        Task { await MovePlanReminder.enable(placeName: name) }
    }

    /// Add (or, with a negative amount, remove) money from the fund. Never below 0.
    func addToFund(_ amount: Double) {
        guard var p = plan else { return }
        p.savedSoFar = max(0, p.savedSoFar + amount)
        plan = p
        persist()
    }

    func clear() {
        plan = nil
        defaults.removeObject(forKey: Self.defaultsKey)
        MovePlanReminder.cancel()
    }

    private func persist() {
        if let plan, let data = try? JSONEncoder().encode(plan) {
            defaults.set(data, forKey: Self.defaultsKey)
        }
    }
}
