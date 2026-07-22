import Foundation
import Observation

/// Saved counties and recently viewed counties, persisted locally.
///
/// Storage is `UserDefaults` holding FIPS codes only — two small string arrays.
/// Nothing about the user is stored, nothing leaves the device, and no account
/// is involved, which keeps the Phase 9 privacy screen short and truthful.
///
/// FIPS codes are stored rather than whole counties so a dataset refresh never
/// leaves stale scores behind: the IDs resolve against the live dataset.
@MainActor
@Observable
final class FavoritesManager {

    private enum Key {
        static let favorites = "debtshield.favorites"
        static let recents = "debtshield.recentlyViewed"
    }

    /// Recents past this are dropped oldest-first.
    static let maxRecents = 10

    private let defaults: UserDefaults

    private(set) var favoriteIDs: [String] {
        didSet { defaults.set(favoriteIDs, forKey: Key.favorites) }
    }

    private(set) var recentIDs: [String] {
        didSet { defaults.set(recentIDs, forKey: Key.recents) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        favoriteIDs = defaults.stringArray(forKey: Key.favorites) ?? []
        recentIDs = defaults.stringArray(forKey: Key.recents) ?? []
    }

    // MARK: - Favourites

    func isFavorite(_ county: ScoredCounty) -> Bool {
        favoriteIDs.contains(county.id)
    }

    func toggleFavorite(_ county: ScoredCounty) {
        if let index = favoriteIDs.firstIndex(of: county.id) {
            favoriteIDs.remove(at: index)
        } else {
            favoriteIDs.append(county.id)
        }
    }

    func removeFavorite(_ county: ScoredCounty) {
        favoriteIDs.removeAll { $0 == county.id }
    }

    /// Resolved against the live dataset, preserving the order they were saved.
    func favorites(in dataset: Dataset) -> [ScoredCounty] {
        resolve(favoriteIDs, in: dataset)
    }

    // MARK: - Recently viewed

    /// Most recent first. Re-visiting a county moves it to the top rather than
    /// adding a duplicate.
    func recordVisit(_ county: ScoredCounty) {
        recentIDs.removeAll { $0 == county.id }
        recentIDs.insert(county.id, at: 0)
        if recentIDs.count > Self.maxRecents {
            recentIDs = Array(recentIDs.prefix(Self.maxRecents))
        }
    }

    func recents(in dataset: Dataset) -> [ScoredCounty] {
        resolve(recentIDs, in: dataset)
    }

    func clearRecents() {
        recentIDs = []
    }

    // MARK: - Resolution

    /// Silently drops IDs that are no longer in the dataset, so a changed CSV
    /// cannot strand the app on a county that does not exist.
    private func resolve(_ ids: [String], in dataset: Dataset) -> [ScoredCounty] {
        let byID = Dictionary(uniqueKeysWithValues: dataset.counties.map { ($0.id, $0) })
        return ids.compactMap { byID[$0] }
    }
}
