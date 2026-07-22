import Foundation
import Observation

/// Which county the user is currently looking at.
///
/// Kept separate from `DataStore` because selection outlives any one screen:
/// Phase 3 adds favourites and recently-viewed here, and Compare Counties reads
/// the same selection. Phase 1's dashboard is unaffected.
@MainActor
@Observable
final class SelectionStore {

    private enum Key {
        static let selected = "debtshield.selectedCounty"
    }

    private let defaults: UserDefaults

    /// FIPS code of the selected county, or nil on first launch.
    ///
    /// Persisted so reopening the app returns to the county you were last
    /// looking at, rather than to the empty state.
    private(set) var selectedID: String? {
        didSet {
            if let selectedID {
                defaults.set(selectedID, forKey: Key.selected)
            } else {
                defaults.removeObject(forKey: Key.selected)
            }
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        selectedID = defaults.string(forKey: Key.selected)
    }

    func select(_ county: ScoredCounty) {
        selectedID = county.id
    }

    func clearSelection() {
        selectedID = nil
    }

    /// Resolves against the live dataset rather than storing a `ScoredCounty`,
    /// so the selection stays correct if the dataset is ever reloaded.
    func selectedCounty(in dataset: Dataset) -> ScoredCounty? {
        guard let selectedID else { return nil }
        return dataset.counties.first { $0.id == selectedID }
    }
}

/// The set of counties currently being compared.
///
/// Held at the app level so switching tabs never loses the comparison. Capped
/// at four: beyond that the bars get too short to read on a phone and the
/// VoiceOver readout of each card becomes unwieldy.
@MainActor
@Observable
final class ComparisonStore {

    static let maxCounties = 4
    static let minimumToCompare = 2

    private(set) var countyIDs: [String] = []

    var canAddMore: Bool { countyIDs.count < Self.maxCounties }
    var hasEnoughToCompare: Bool { countyIDs.count >= Self.minimumToCompare }

    func contains(_ county: ScoredCounty) -> Bool {
        countyIDs.contains(county.id)
    }

    /// Silently ignores duplicates and over-capacity adds so callers do not
    /// each have to guard.
    func add(_ county: ScoredCounty) {
        guard canAddMore, !contains(county) else { return }
        countyIDs.append(county.id)
    }

    func remove(_ county: ScoredCounty) {
        countyIDs.removeAll { $0 == county.id }
    }

    func removeAll() {
        countyIDs = []
    }

    func counties(in dataset: Dataset) -> [ScoredCounty] {
        let byID = Dictionary(uniqueKeysWithValues: dataset.counties.map { ($0.id, $0) })
        return countyIDs.compactMap { byID[$0] }
    }
}
