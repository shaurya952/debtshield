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

    // MARK: - Entity extraction

    /// Finds a county named anywhere inside a free-form sentence.
    ///
    /// The chatbot needs this: "what is the poverty rate in Cook County
    /// Illinois" should be understood as a question *about Cook County*, but a
    /// plain search over the whole sentence returns nothing useful because the
    /// question words drown out the name.
    ///
    /// Scans word n-grams from longest to shortest so "east carroll parish"
    /// wins over "carroll", and only accepts an exact name match — a partial
    /// hit like "co" must not silently bind the answer to some random county.
    /// Ambiguous names ("Washington County" exists in 30 states) are resolved
    /// by a state named elsewhere in the same sentence, and otherwise refused.
    func mentionedCounty(in text: String) -> ScoredCounty? {
        let found = countyMentions(in: text)
        return found.count == 1 ? found[0] : nil
    }

    /// Every county matching the longest name found in the sentence.
    ///
    /// Empty when nothing matched, one when unambiguous, several when the name
    /// is shared — "Washington County" exists in 30 states. The caller decides
    /// whether to answer or ask which state.
    func countyMentions(in text: String) -> [ScoredCounty] {
        let normalised = Self.normalise(text)
        let words = normalised.split(separator: " ").map(String.init)
        guard !words.isEmpty else { return [] }

        let mentionedState = entries.first { normalised.contains($0.state) }?.state

        for length in stride(from: min(4, words.count), through: 1, by: -1) {
            for start in 0...(words.count - length) {
                let phrase = words[start..<(start + length)].joined(separator: " ")
                guard phrase.count >= 3 else { continue }

                var matches = entries.filter { $0.baseName == phrase || $0.name == phrase }
                guard !matches.isEmpty else { continue }

                if matches.count > 1, let mentionedState {
                    let narrowed = matches.filter { $0.state == mentionedState }
                    // Only narrow if it actually leaves something. "Washington
                    // County" contains the state name "Washington", but there
                    // is no Washington County *in* Washington — filtering there
                    // would wrongly report no county at all.
                    if !narrowed.isEmpty { matches = narrowed }
                }
                return matches.map(\.county)
            }
        }
        return []
    }

    /// Finds a state named anywhere inside a sentence.
    func mentionedState(in text: String) -> String? {
        let normalised = Self.normalise(text)
        // A state name directly followed by a county suffix is part of a county
        // name, not a state reference: "Washington County" is a county.
        let suffixes = ["county", "parish", "borough", "city", "municipality", "census area"]
        return entries.first { entry in
            guard let range = normalised.range(of: entry.state) else { return false }
            let rest = normalised[range.upperBound...].trimmingCharacters(in: .whitespaces)
            return !suffixes.contains { rest.hasPrefix($0) }
        }?.county.state
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
    func results(for rawQuery: String, riskFilter: RiskLevel? = nil, limit: Int = 60) -> Outcome {
        let matches = search(rawQuery, riskFilter: riskFilter, limit: Int.max)
        return Outcome(
            counties: Array(matches.prefix(limit)),
            totalMatches: matches.count
        )
    }

    func search(_ rawQuery: String, riskFilter: RiskLevel? = nil, limit: Int = 60) -> [ScoredCounty] {
        let query = Self.normalise(rawQuery)
        let pool = riskFilter.map { level in entries.filter { $0.county.riskLevel == level } } ?? entries

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
