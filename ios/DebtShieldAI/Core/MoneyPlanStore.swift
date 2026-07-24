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
    static let historyKey = "debtshield.history"
    static let currentMonthKey = "debtshield.currentMonth"

    /// The current plan. Reading is free; writing goes through `save` so it
    /// always hits disk.
    private(set) var plan: MoneyPlan

    /// Finished months, most recent first. Capped so it never grows unbounded.
    private(set) var history: [MonthRecord] = []

    /// The "yyyy-MM" month the current `plan` belongs to. Empty until the first
    /// rollover check stamps it.
    private(set) var month: String = ""

    /// Where the person lives, if they've chosen it — used only to compare
    /// their rent to the local typical. FIPS is the key into the county data;
    /// the name is kept alongside so a label can show even before that data
    /// finishes loading.
    private(set) var homeCountyFIPS: String?
    private(set) var homeCountyName: String?

    /// Keep at most a year of history — plenty for a trend, and bounded.
    static let historyLimit = 12

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
        if let data = defaults.data(forKey: Self.historyKey),
           let decoded = try? JSONDecoder().decode([MonthRecord].self, from: data) {
            history = decoded
        }
        month = defaults.string(forKey: Self.currentMonthKey) ?? ""
    }

    /// The most recent finished month, for the "vs last month" trend.
    var lastMonth: MonthRecord? { history.first }

    /// Roll the current plan into history when the calendar month has changed.
    ///
    /// Called on launch. On the first run it just stamps the current month. When
    /// a new month has begun and the finished month held real data, that month
    /// is archived and the plan carries forward as the new month's starting
    /// point — bills usually recur, and the person can adjust.
    func rollOverIfNeeded(now: Date = Date()) {
        let key = MonthRecord.key(for: now)
        guard month != key else { return }
        if !month.isEmpty, plan.isComplete {
            history.insert(MonthRecord(monthKey: month, plan: plan), at: 0)
            if history.count > Self.historyLimit { history.removeLast(history.count - Self.historyLimit) }
            persistHistory()
        }
        month = key
        defaults.set(month, forKey: Self.currentMonthKey)
    }

    private func persistHistory() {
        if let data = try? JSONEncoder().encode(history) {
            defaults.set(data, forKey: Self.historyKey)
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
    /// Clears the month history too, so nothing lingers.
    func clear() {
        plan = .empty
        history = []
        defaults.removeObject(forKey: Self.defaultsKey)
        defaults.removeObject(forKey: Self.historyKey)
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

    /// A store seeded with a few months of history, for previewing the trend.
    static func previewWithHistory() -> MoneyPlanStore {
        let suite = UserDefaults(suiteName: "preview.moneyplan.history") ?? .standard
        let store = MoneyPlanStore(defaults: suite)
        store.history = [
            MonthRecord(monthKey: "2026-06", plan: MoneyPlan(monthlyIncome: 3000, housing: 1500, food: 350, energy: 180, debtPayments: 150)),
            MonthRecord(monthKey: "2026-05", plan: MoneyPlan(monthlyIncome: 3000, housing: 1500, food: 420, energy: 200, debtPayments: 300)),
            MonthRecord(monthKey: "2026-04", plan: MoneyPlan(monthlyIncome: 2800, housing: 1500, food: 400, energy: 220, debtPayments: 300))
        ]
        store.month = "2026-07"
        store.save(.sampleOkay)
        return store
    }
}
#endif
