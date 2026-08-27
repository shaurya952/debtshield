import Foundation
import Observation

/// A shortlist of places the person has saved — their candidates for a move.
///
/// Just an ordered set of county FIPS codes, kept on the device in `UserDefaults`
/// alongside everything else (`debtshield.*`). Like the rest of the app it never
/// leaves the phone. Most-recently-saved first, so the shortlist reads like a
/// list you're building.
@MainActor
@Observable
final class SavedPlacesStore {
    static let defaultsKey = "debtshield.savedPlaces"

    private(set) var fips: [String] = []
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let stored = defaults.array(forKey: Self.defaultsKey) as? [String] {
            fips = stored
        }
    }

    var isEmpty: Bool { fips.isEmpty }
    func isSaved(_ code: String) -> Bool { fips.contains(code) }

    /// Save or un-save a place. Saving puts it at the top of the shortlist.
    func toggle(_ code: String) {
        if let i = fips.firstIndex(of: code) {
            fips.remove(at: i)
        } else {
            fips.insert(code, at: 0)
        }
        defaults.set(fips, forKey: Self.defaultsKey)
    }
}
