import Foundation
import Observation

/// Owns the person's money numbers and keeps them on the device.
///
/// Persistence is a single JSON blob in `UserDefaults`, the same on-device,
/// no-account, no-network approach `FavoritesManager` already uses for starred
/// counties. Nothing here is uploaded, synced, or shared — the numbers never
/// leave the phone, which is the promise the privacy screen makes.
@MainActor
@Observable
final class MoneyPlanStore {

    static let defaultsKey = "debtshield.moneyPlan"

    /// The current plan. Reading is free; writing goes through `save` so it
    /// always hits disk.
    private(set) var plan: MoneyPlan

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.defaultsKey),
           let decoded = try? JSONDecoder().decode(MoneyPlan.self, from: data) {
            plan = decoded
        } else {
            plan = .empty
        }
    }

    /// Replace the plan and persist it. A failed encode leaves the in-memory
    /// value updated but simply doesn't write — the next successful save fixes
    /// it, and there is nothing sensitive to recover.
    func save(_ newPlan: MoneyPlan) {
        plan = newPlan
        if let data = try? JSONEncoder().encode(newPlan) {
            defaults.set(data, forKey: Self.defaultsKey)
        }
    }

    /// Wipe the numbers from memory and disk — the "start over" affordance.
    func clear() {
        plan = .empty
        defaults.removeObject(forKey: Self.defaultsKey)
    }
}

#if DEBUG
extension MoneyPlanStore {
    /// An isolated store seeded with a plan, for previews. Uses a throwaway
    /// defaults suite so preview data never touches the real app's numbers.
    static func preview(_ plan: MoneyPlan) -> MoneyPlanStore {
        let suite = UserDefaults(suiteName: "preview.moneyplan") ?? .standard
        let store = MoneyPlanStore(defaults: suite)
        store.save(plan)
        return store
    }
}
#endif
