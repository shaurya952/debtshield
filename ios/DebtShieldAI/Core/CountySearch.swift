import Foundation

/// Fast, forgiving search over all 3,142 counties.
///
/// The Streamlit version used `str.contains(search_term)` on "County, State",
/// which meant "cook illinois" found nothing and "Doña" only matched if you
/// typed the tilde. This index normalises once at load time and then supports:
///
/// - county names (`autauga`)
/// - state names (`alabama`)
/// - both together in either order (`cook illinois`, `illinois cook`)
/// - partial spelling (`autau`, `mississi`)
/// - the bare county name without its suffix (`east carroll` → East Carroll Parish)
/// - accents typed or omitted (`dona ana` → Doña Ana County)
struct CountySearchIndex: Sendable {

    struct Entry: Sendable {
        let county: ScoredCounty
        /// "autauga county"
        let name: String
        /// "autauga" — suffix stripped
        let baseName: String
        /// "alabama"
        let state: String
        /// "autauga county alabama"
        let haystack: String
    }

    private let entries: [Entry]

    init(counties: [ScoredCounty]) {
        entries = counties.map { county in
            let name = Self.normalise(county.county)
            let state = Self.normalise(county.state)
            return Entry(
                county: county,
                name: name,
                baseName: Self.stripSuffix(name),
                state: state,
                haystack: "\(name) \(state)"
            )
        }
    }

    // MARK: - Normalisation

    /// Case- and accent-insensitive, so "Doña Ana" and "dona ana" are the same
    /// string by the time we compare.
    static func normalise(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Drops the administrative suffix so a user can type what they actually
    /// call the place. Louisiana uses Parish, Alaska uses Borough and Census
    /// Area, Virginia has independent Cities.
    static func stripSuffix(_ normalisedName: String) -> String {
        // Longest first. " city and borough" must be tested before " borough",
        // or Juneau City and Borough strips down to "juneau city and".
        let suffixes = [" city and borough", " census area", " municipality",
                        " borough", " parish", " county", " city"]
        for suffix in suffixes where normalisedName.hasSuffix(suffix) {
            return String(normalisedName.dropLast(suffix.count))
        }
        return normalisedName
    }

    // MARK: - Search

    /// Lower rank sorts first. Exact and prefix matches beat substring matches,
    /// so typing "cook" puts Cook County above Coconino and Woodcock.
    private static func rank(_ entry: Entry, query: String) -> Int? {
        if entry.baseName == query || entry.name == query { return 0 }
        if entry.baseName.hasPrefix(query) { return 1 }
        if entry.name.hasPrefix(query) { return 2 }
        if entry.state == query { return 3 }
        if entry.state.hasPrefix(query) { return 4 }
        if entry.name.contains(query) { return 5 }
        if entry.state.contains(query) { return 6 }
        return nil
    }

    /// Multi-word queries require every word to appear somewhere in the entry,
    /// which is what makes "cook illinois" and "illinois cook" both work.
    private static func matchesAllTokens(_ entry: Entry, tokens: [String]) -> Bool {
        tokens.allSatisfy { entry.haystack.contains($0) }
    }

    /// Results plus the pre-limit match count, from one pass.
    struct Outcome: Equatable, Sendable {
        var counties: [ScoredCounty]
        /// Total matches before `limit` was applied.
        var totalMatches: Int

        static let empty = Outcome(counties: [], totalMatches: 0)
    }

    /// Single entry point for the UI. Returning both values together keeps the
    /// per-keystroke cost to one pass over the 3,142 entries.
    func results(for rawQuery: String, limit: Int = 60) -> Outcome {
        let matches = search(rawQuery, limit: Int.max)
        return Outcome(
            counties: Array(matches.prefix(limit)),
            totalMatches: matches.count
        )
    }

    func search(_ rawQuery: String, limit: Int = 60) -> [ScoredCounty] {
        let query = Self.normalise(rawQuery)
        let pool = entries

        guard !query.isEmpty else {
            // No query: show the pool alphabetically rather than in file order.
            return Array(
                pool.sorted { $0.haystack < $1.haystack }
                    .prefix(limit)
                    .map(\.county)
            )
        }

        let tokens = query.split(separator: " ").map(String.init)

        var ranked: [(rank: Int, entry: Entry)] = []
        for entry in pool {
            if tokens.count > 1 {
                guard Self.matchesAllTokens(entry, tokens: tokens) else { continue }
                // An entry containing the whole phrase always wins. Without
                // this, "st. louis" ranks St. Bernard Parish first — "st."
                // prefix-matches the name and "louis" is inside "Louisiana".
                if entry.name.contains(query) || entry.baseName.hasPrefix(query) {
                    ranked.append((0, entry))
                    continue
                }
                // Otherwise rank by the strongest single token.
                let best = tokens.compactMap { Self.rank(entry, query: $0) }.min() ?? 7
                // Multi-token matches spread across name and state rank below
                // any single-token phrase match.
                ranked.append((best + 1, entry))
            } else if let rank = Self.rank(entry, query: query) {
                ranked.append((rank, entry))
            }
        }

        return Array(
            ranked.sorted { lhs, rhs in
                lhs.rank == rhs.rank
                    ? lhs.entry.haystack < rhs.entry.haystack
                    : lhs.rank < rhs.rank
            }
            .prefix(limit)
            .map(\.entry.county)
        )
    }

}
