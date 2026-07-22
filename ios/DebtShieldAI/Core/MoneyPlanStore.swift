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
    static let homeCountyKey = "debtshield.homeCounty"

    /// The current plan. Reading is free; writing goes through `save` so it
    /// always hits disk.
    private(set) var plan: MoneyPlan

    /// Where the person lives, if they've chosen it — used only to compare
    /// their rent to the local typical. FIPS is the key into the county data;
    /// the name is kept alongside so a label can show even before that data
    /// finishes loading.
    private(set) var homeCountyFIPS: String?
    private(set) var homeCountyName: String?

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.defaultsKey),
           let decoded = try? JSONDecoder().decode(MoneyPlan.self, from: data) {
            plan = decoded
        } else {
            plan = .empty
        }
        if let data = defaults.data(forKey: Self.homeCountyKey),
           let home = try? JSONDecoder().decode(HomeCounty.self, from: data) {
            homeCountyFIPS = home.fips
            homeCountyName = home.name
        }
    }

    /// Remember where the person lives, for the local rent comparison.
    func setHomeCounty(fips: String, name: String) {
        homeCountyFIPS = fips
        homeCountyName = name
        if let data = try? JSONEncoder().encode(HomeCounty(fips: fips, name: name)) {
            defaults.set(data, forKey: Self.homeCountyKey)
        }
    }

    func clearHomeCounty() {
        homeCountyFIPS = nil
        homeCountyName = nil
        defaults.removeObject(forKey: Self.homeCountyKey)
    }

    private struct HomeCounty: Codable {
        let fips: String
        let name: String
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
        clearHomeCounty()
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
