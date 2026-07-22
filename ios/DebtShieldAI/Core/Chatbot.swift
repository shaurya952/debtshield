import Foundation

/// One turn of the conversation.
struct ChatMessage: Identifiable, Sendable {
    enum Role: Sendable {
        case user
        case assistant

        /// Spoken prefix so a screen-reader user always knows who is talking.
        var accessibilityPrefix: String {
            switch self {
            case .user: return "You asked"
            case .assistant: return "DebtShield replied"
            }
        }
    }

    let id: UUID
    let role: Role
    let text: String
    /// Where the numbers came from. Assistant messages only.
    let provenance: String?
    /// Suggested next questions.
    let followUps: [String]

    init(id: UUID = UUID(), role: Role, text: String, provenance: String? = nil, followUps: [String] = []) {
        self.id = id
        self.role = role
        self.text = text
        self.provenance = provenance
        self.followUps = followUps
    }
}

/// What the engine produced for one question.
struct ChatAnswer: Sendable {
    var text: String
    var provenance: String?
    var followUps: [String] = []
    /// True when the engine declined rather than answered. Declines never
    /// contain figures.
    var isDecline: Bool = false
}

/// Ask DebtShield.
///
/// ## Why this is not a language model
///
/// The requirement is that the assistant must never invent a statistic. A
/// generative model cannot give that guarantee — it produces plausible text,
/// and plausible text about a county includes plausible-looking numbers.
///
/// So this is a deterministic responder. It resolves what the question is
/// *about* (which county or state), decides what it is *asking* via
/// `ChatIntent`, then **computes** every figure it quotes from `Dataset` and
/// `ScoredCounty` at the moment it answers. No number is ever written into a
/// response string by hand. If it cannot place the question, it says so and
/// offers what it can answer — it does not improvise.
///
/// ## Understanding a question
///
/// Two upgrades over the first version, both aimed at answering more of what
/// people actually type:
///
/// 1. **Subject extraction.** A county or state named anywhere in the sentence
///    becomes the subject, so "what's the poverty rate in Cook County" works
///    without the county being selected on screen.
/// 2. **Scored intents.** Every intent is scored against the question and the
///    strongest wins, rather than the first keyword in a fixed chain.
enum ChatEngine {

    // MARK: - Entry point

    static func respond(
        to question: String,
        dataset: Dataset,
        searchIndex: CountySearchIndex,
        county selected: ScoredCounty?
    ) -> ChatAnswer {
        let q = normalise(question)

        guard !q.isEmpty else {
            return ChatAnswer(
                text: "Ask me about a county's risk level, what drives it, the figures behind it, or how the score is worked out.",
                followUps: quickPrompts(for: selected)
            )
        }

        // Refusals come first: they must win regardless of what else matches.
        if let answer = personalAdviceDecline(q) { return answer }
        if let answer = forecastDecline(q) { return answer }

        // What is the question about? A county named in the sentence beats the
        // one selected on screen, so you can ask about anywhere without
        // changing your selection.
        let mentions = searchIndex.countyMentions(in: question)
        let mentionedState = searchIndex.mentionedState(in: question)

        // "Mississippi" is both a state and a county name in two states. With
        // no county suffix anywhere in the sentence, the state is what was
        // meant — asking "which Mississippi County?" would be obtuse.
        let namesACountyExplicitly = has(q, ["county", "parish", "borough", "municipality", "census area"])
        if let mentionedState, !namesACountyExplicitly,
           q.contains(normalise(mentionedState)) {
            if ChatIntent.best(for: q) == nil || has(q, ["tell me about", "how is", "about", "summary", "state"]) {
                return stateSummary(mentionedState, dataset: dataset)
            }
        }

        // A shared name like "Washington County" exists in 30 states. Asking is
        // the only honest option — answering about whichever county happened to
        // be selected would look like an answer about the one they named.
        if mentions.count > 1 {
            let states = mentions.prefix(4).map(\.state).sorted()
            let extra = mentions.count > states.count ? ", and others" : ""
            return ChatAnswer(
                text: "There is more than one **\(mentions[0].county)** — it appears in \(ListFormatter.localizedString(byJoining: states))\(extra). Which one do you mean? Add the state, for example \"\(mentions[0].county), \(states[0])\".",
                followUps: mentions.prefix(3).map { "Tell me about \($0.county), \($0.state)" },
                isDecline: true
            )
        }

        let mentioned = mentions.first
        // A state named on its own is the subject, rather than whatever county
        // happens to be selected on screen.
        let subject = mentioned ?? (mentionedState != nil ? nil : selected)

        // Comparisons need two subjects, so they are handled before the rest.
        if let answer = comparison(q, question: question, dataset: dataset, searchIndex: searchIndex) {
            return answer
        }

        let intent = ChatIntent.best(for: q)

        switch intent {
        case .greeting:
            return greeting(for: subject)
        case .capabilities:
            return capabilities(dataset: dataset, subject: subject)
        case .define:
            // A glossary term wins, then risk levels, then the methodology —
            // but only if the question is actually about something we cover.
            // Without this guard "what is the capital of France" matches the
            // phrase "what is the" and gets an answer about the index.
            if let answer = definition(q) { return answer }
            if let answer = riskLevelMeaning(q) { return answer }
            if has(q, ["index", "score", "risk", "calculated", "formula", "rating", "app",
                       "debtshield", "county", "counties"]) {
                return methodology(dataset: dataset)
            }
            return decline(county: subject)
        case .riskLevelMeaning:
            return riskLevelMeaning(q) ?? methodology(dataset: dataset)
        case .methodology:
            return methodology(dataset: dataset)
        case .dataSource:
            return dataSource(dataset: dataset)
        case .privacy:
            return privacy()
        case .extremes:
            return extremes(q, dataset: dataset)
        case .counts:
            return counts(q, dataset: dataset)
        case .nationalAverage:
            return nationalAverage(dataset: dataset)
        case .stateRanking:
            return stateRanking(q, dataset: dataset)
        case .stateSummary:
            if let state = mentionedState { return stateSummary(state, dataset: dataset) }
            if let subject { return stateSummary(subject.state, dataset: dataset) }
            return stateRanking(q, dataset: dataset)
        default:
            break
        }

        // A state was named and no county was — answer about the state.
        if mentioned == nil, let mentionedState {
            return stateSummary(mentionedState, dataset: dataset)
        }

        // Everything remaining is about a specific county.
        guard let subject else {
            // A state was named but no county — answer at state level.
            if let mentionedState { return stateSummary(mentionedState, dataset: dataset) }
            return ChatAnswer(
                text: "I need to know which county you mean. Name one in your question — \"poverty rate in Cook County, Illinois\" — or choose one on the County tab.",
                followUps: ["Which county is highest risk?", "How is the score worked out?"],
                isDecline: true
            )
        }

        if !subject.isScored, intent != nil {
            return unscoredExplanation(subject)
        }

        switch intent {
        case .indicator:
            return indicator(q, county: subject, dataset: dataset)
        case .driverScore:
            return driverScore(q, county: subject, dataset: dataset)
        case .whyAtRisk:
            return whyAtRisk(county: subject, dataset: dataset)
        case .recommendations:
            return recommendations(q, county: subject, dataset: dataset)
        case .rank:
            return rank(county: subject, dataset: dataset)
        case .summary:
            return ChatAnswer(
                text: describe(subject, in: dataset),
                provenance: provenance(for: subject),
                followUps: ["Why is \(subject.county) at risk?", "What could help \(subject.county)?"]
            )
        default:
            break
        }

        // A county was clearly named but the question was not understood.
        if mentioned != nil {
            return ChatAnswer(
                text: describe(subject, in: dataset)
                    + "\n\nI wasn't sure what you were asking, so that's the summary. Try asking why it's at risk, what could help, or for a specific figure like its poverty rate.",
                provenance: provenance(for: subject),
                followUps: ["Why is \(subject.county) at risk?", "What is \(subject.county)'s poverty rate?"]
            )
        }

        return decline(county: subject)
    }

    // MARK: - Text helpers

    static func normalise(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func has(_ q: String, _ needles: [String]) -> Bool {
        needles.contains { q.contains($0) }
    }

    private static func provenance(for county: ScoredCounty) -> String {
        let year = county.record.year.map { String($0) } ?? "latest"
        return "\(county.displayName) · U.S. Census ACS 5-Year, \(year)"
    }

    // MARK: - Declines

    /// Questions about the reader's own situation. The app is educational and
    /// is not licensed to advise anyone, so this never attempts an answer.
    private static func personalAdviceDecline(_ q: String) -> ChatAnswer? {
        let markers = ["should i", "should we", "should my", "can i get", "am i eligible",
                       "my rent", "my debt", "my credit", "my loan", "my mortgage",
                       "help me pay", "i cant afford", "i can't afford", "advise me",
                       "what do i do", "am i at risk", "my bills", "my income",
                       "qualify for", "apply for"]
        guard has(q, markers) else { return nil }
        return ChatAnswer(
            text: "I can't help with an individual's situation. DebtShield AI looks at counties as a whole, and it isn't financial, legal, or benefits advice.\n\nFor personal help, 211 connects to local assistance in most of the United States, and HUD-approved housing counselling agencies offer free guidance.",
            followUps: ["What support exists for housing pressure?", "What does high risk mean?"],
            isDecline: true
        )
    }

    /// Predictions. The index describes the present; nothing here forecasts.
    private static func forecastDecline(_ q: String) -> ChatAnswer? {
        let markers = ["predict", "forecast", "next year", "next month", "will it get",
                       "going to get", "in the future", "future risk", "by 2026", "by 2030",
                       "what will happen", "projection"]
        guard has(q, markers) else { return nil }
        return ChatAnswer(
            text: "I can't forecast. The Financial Distress Index describes conditions in the data as it was collected — it doesn't project forward.\n\nThe Scenario Simulator on a county's page lets you try different figures and see what the score would be, but that's an estimate of the formula, not a prediction of what will happen.",
            followUps: ["How is the score worked out?", "What drives this county's risk?"],
            isDecline: true
        )
    }

    /// The honest fallback.
    private static func decline(county: ScoredCounty?) -> ChatAnswer {
        var text = "I'm not sure what you're asking. I can only work from the county data built into this app."
        if let county {
            text += "\n\nFor **\(county.displayName)** I can give its risk level, what drives it, the figures behind the score, how it ranks, and what kinds of support exist."
        }
        return ChatAnswer(text: text, followUps: quickPrompts(for: county), isDecline: true)
    }

    // MARK: - General intents

    private static func greeting(for county: ScoredCounty?) -> ChatAnswer {
        let subject = county.map { "**\($0.displayName)**" } ?? "any U.S. county"
        return ChatAnswer(
            text: "Hello. I can explain \(subject) — its risk level, what drives it, and the figures behind the score. You can also name any other county in your question.",
            followUps: quickPrompts(for: county)
        )
    }

    private static func capabilities(dataset: Dataset, subject: ScoredCounty?) -> ChatAnswer {
        return ChatAnswer(
            text: """
            I answer from the \(dataset.counties.count.formatted(.number)) counties built into this app. Things I can do:

            · Summarise any county — name it in your question
            · Explain what drives a county's risk
            · Give a specific figure: income, rent, rent burden, poverty, unemployment
            · Compare two counties
            · Tell you the highest and lowest scoring counties, or how a state is doing
            · Explain the score, the risk levels, and any term in the glossary

            What I won't do is guess. If the data doesn't cover something, I'll say so, and I can't advise anyone on their own finances.
            """,
            followUps: quickPrompts(for: subject)
        )
    }

    /// Definitions come from the same glossary the About tab shows, so the two
    /// can never drift apart.
    private static func definition(_ q: String) -> ChatAnswer? {
        // Whole term first, then any significant word of it — "delinquency"
        // should find "Credit delinquency".
        let match = Glossary.terms.first { q.contains(normalise($0.term)) }
            ?? Glossary.terms.first { term in
                normalise(term.term)
                    .split(separator: " ")
                    .filter { $0.count > 4 }
                    .contains { q.contains($0) }
            }
        guard let match else { return nil }
        var text = "**\(match.term)** — \(match.definition)"
        if let example = match.example { text += "\n\n\(example)" }
        return ChatAnswer(
            text: text,
            provenance: "Glossary",
            followUps: ["How is the score worked out?", "Which county is highest risk?"]
        )
    }

    private static func riskLevelMeaning(_ q: String) -> ChatAnswer? {
        let level: RiskLevel?
        if has(q, ["low risk", "low-risk"]) { level = .low }
        else if has(q, ["medium risk", "moderate risk", "medium-risk"]) { level = .medium }
        else if has(q, ["high risk", "high-risk"]) { level = .high }
        else { level = nil }
        guard let level else { return nil }

        let bounds: String
        switch level {
        case .low: bounds = "below 35"
        case .medium: bounds = "35 up to 65"
        case .high: bounds = "65 or above"
        }
        return ChatAnswer(
            text: "**\(level.label) risk** means the Financial Distress Index is \(bounds) out of 100.\n\n\(level.plainEnglish)",
            followUps: ["How is the score worked out?", "Which county is highest risk?"]
        )
    }

    private static func methodology(dataset: Dataset) -> ChatAnswer {
        let measured = DriverKind.allCases.filter { dataset.capabilities.measuredDrivers.contains($0) }
        let unmeasured = DriverKind.allCases.filter { !dataset.capabilities.measuredDrivers.contains($0) }
        let weights = RiskScoring.normalisedWeights(for: dataset.capabilities)

        let weightLines = measured
            .sorted { (weights[$0] ?? 0) > (weights[$1] ?? 0) }
            .map { "· \($0.title): \(Int(((weights[$0] ?? 0) * 100).rounded()))% of the score" }
            .joined(separator: "\n")

        var text = """
        The Financial Distress Index is a 0–100 score. Higher means more financial pressure. It is a fixed formula, not a machine-learning prediction — the same figures always give the same score.

        For this data it combines:
        \(weightLines)

        Below 35 is low risk, 35 to 65 is medium, 65 and above is high.
        """
        if !unmeasured.isEmpty {
            text += "\n\n\(unmeasured.map(\.title).joined(separator: ", ")) would normally count too, but this dataset has no source for them, so they are left out rather than guessed."
        }
        return ChatAnswer(
            text: text,
            provenance: "Built-in methodology",
            followUps: ["What does high risk mean?", "Where does the data come from?"]
        )
    }

    private static func dataSource(dataset: Dataset) -> ChatAnswer {
        let years = Set(dataset.counties.compactMap(\.record.year)).sorted()
        let yearText = years.count == 1 ? "\(years[0])" : years.map(String.init).joined(separator: ", ")
        return ChatAnswer(
            text: """
            The figures come from the U.S. Census Bureau's American Community Survey 5-Year estimates\(years.isEmpty ? "" : ", \(yearText)").

            That covers \(dataset.counties.count.formatted(.number)) counties across \(dataset.states.count) states. \(dataset.scoredCounties.count.formatted(.number)) have enough data to score; \(dataset.unscoredCounties.count) do not, because the Census doesn't publish estimates for very small populations.

            Nothing is downloaded — the data ships inside the app and never leaves your device.
            """,
            provenance: dataset.sourceDescription,
            followUps: ["How is the score worked out?", "How many counties are high risk?"]
        )
    }

    private static func privacy() -> ChatAnswer {
        ChatAnswer(
            text: "Nothing you type here leaves your device, and nothing is stored. The app has no account, makes no network requests, and collects no analytics.\n\nThe only things saved are your starred counties, the last ten you opened, and which version of the recommendations you last read — all as county codes on this device.",
            provenance: "Privacy screen, About tab",
            followUps: ["Where does the data come from?", "What can you do?"]
        )
    }

    // MARK: - National intents

    private static func extremes(_ q: String, dataset: Dataset) -> ChatAnswer {
        let wantsLowest = has(q, ["safest", "lowest", "least at risk", "best county", "best off", "best counties"])
        let list = wantsLowest ? dataset.lowestRisk : dataset.highestRisk
        let wantsMany = has(q, ["top 10", "top ten", "counties", "list"])

        guard let top = list.first, let index = top.index else {
            return decline(county: nil)
        }

        if wantsMany {
            let rows = list.prefix(10).enumerated().compactMap { position, county -> String? in
                county.index.map { "\(position + 1). \(county.displayName) — \($0.scoreText)" }
            }.joined(separator: "\n")
            return ChatAnswer(
                text: "The 10 \(wantsLowest ? "lowest" : "highest")-scoring counties:\n\n\(rows)",
                provenance: "\(dataset.scoredCounties.count.formatted(.number)) scored counties",
                followUps: ["Why is \(top.county) at risk?", "How is the score worked out?"]
            )
        }

        let others = list.dropFirst().prefix(2).compactMap { c in
            c.index.map { "\(c.displayName) at \($0.scoreText)" }
        }
        var text = "The \(wantsLowest ? "lowest" : "highest")-scoring county in this data is **\(top.displayName)**, at \(index.scoreText) out of 100 — \(top.riskLevel?.label.lowercased() ?? "no") risk."
        if !others.isEmpty { text += "\n\nNext: \(others.joined(separator: ", "))." }
        return ChatAnswer(
            text: text,
            provenance: "\(dataset.scoredCounties.count.formatted(.number)) scored counties",
            followUps: ["Why is \(top.county) at risk?", "Show me the top 10"]
        )
    }

    private static func counts(_ q: String, dataset: Dataset) -> ChatAnswer {
        let level: RiskLevel?
        if has(q, ["high risk", "high-risk"]) { level = .high }
        else if has(q, ["medium", "moderate"]) { level = .medium }
        else if has(q, ["low risk", "low-risk"]) { level = .low }
        else { level = nil }

        if has(q, ["states"]) {
            return ChatAnswer(
                text: "The data covers **\(dataset.states.count) states**, including the District of Columbia.",
                provenance: dataset.sourceDescription,
                followUps: ["Which state has the highest average?", "How many counties are high risk?"]
            )
        }

        if let level {
            let count = dataset.count(of: level)
            let share = Double(count) / Double(dataset.scoredCounties.count) * 100
            return ChatAnswer(
                text: "**\(count.formatted(.number))** of \(dataset.scoredCounties.count.formatted(.number)) scored counties are \(level.label.lowercased()) risk — about \(share.scoreText)%.\n\n\(level.plainEnglish)",
                provenance: "\(dataset.scoredCounties.count.formatted(.number)) scored counties",
                followUps: ["Which county is highest risk?", "What does \(level.label.lowercased()) risk mean?"]
            )
        }

        return ChatAnswer(
            text: """
            The data has **\(dataset.counties.count.formatted(.number)) counties** across \(dataset.states.count) states.

            · \(dataset.count(of: .low).formatted(.number)) low risk
            · \(dataset.count(of: .medium).formatted(.number)) medium risk
            · \(dataset.count(of: .high).formatted(.number)) high risk
            · \(dataset.unscoredCounties.count) without enough data to score
            """,
            provenance: dataset.sourceDescription,
            followUps: ["Which county is highest risk?", "What is the national average?"]
        )
    }

    private static func nationalAverage(dataset: Dataset) -> ChatAnswer {
        ChatAnswer(
            text: "The average Financial Distress Index across the \(dataset.scoredCounties.count.formatted(.number)) scored counties is **\(dataset.averageIndex.scoreText)** out of 100 — comfortably inside the low-risk band.\n\nMost counties sit well below the 35 threshold; the pressure is concentrated in a minority.",
            provenance: "\(dataset.scoredCounties.count.formatted(.number)) scored counties",
            followUps: ["How many counties are high risk?", "Which county is highest risk?"]
        )
    }

    private static func stateSummary(_ state: String, dataset: Dataset) -> ChatAnswer {
        guard let match = dataset.stateSummaries().first(where: { $0.state == state }) else {
            return decline(county: nil)
        }
        let elevated = match.mediumCount + match.highCount
        let rank = dataset.stateSummaries().firstIndex { $0.state == state }.map { $0 + 1 }
        var text = "**\(match.state)** has \(match.totalCount) counties in this data, averaging \(match.averageIndex.scoreText) out of 100."
        if let rank { text += " That ranks \(rank) of \(dataset.states.count) states by average." }
        text += "\n\n" + (elevated == 0
            ? "All of its scored counties are low risk."
            : "\(elevated) of \(match.scoredCount) are at medium or high risk.")
        return ChatAnswer(
            text: text,
            provenance: "\(match.state) · \(match.scoredCount) scored counties",
            followUps: ["Which state has the highest average?", "Which county is highest risk?"]
        )
    }

    private static func stateRanking(_ q: String, dataset: Dataset) -> ChatAnswer {
        let summaries = dataset.stateSummaries()
        let wantsLowest = has(q, ["best", "lowest", "safest"])
        let ordered = wantsLowest ? summaries.reversed().map { $0 } : summaries
        let rows = ordered.prefix(5).enumerated().map { position, summary in
            "\(position + 1). \(summary.state) — \(summary.averageIndex.scoreText)"
        }.joined(separator: "\n")
        return ChatAnswer(
            text: "States by average Financial Distress Index, \(wantsLowest ? "lowest" : "highest") first:\n\n\(rows)",
            provenance: "\(dataset.states.count) states",
            followUps: ["Which county is highest risk?", "What is the national average?"]
        )
    }

    // MARK: - County intents

    private static func indicator(_ q: String, county: ScoredCounty, dataset: Dataset) -> ChatAnswer {
        let record = county.record

        func answer(_ label: String, _ value: String, _ note: String) -> ChatAnswer {
            ChatAnswer(
                text: "\(label) in **\(county.displayName)** is **\(value)**.\n\n\(note)",
                provenance: provenance(for: county),
                followUps: ["Why is \(county.county) at risk?", "How does \(county.county) rank?"]
            )
        }

        if has(q, ["income", "earn", "salary", "wages", "wage"]) {
            guard let income = record.medianHouseholdIncome else {
                return notReported("median household income", county: county)
            }
            return answer("Median household income",
                          income.formatted(.currency(code: "USD").precision(.fractionLength(0))),
                          "That is the midpoint: half of households earn more, half less.")
        }
        if has(q, ["rent burden"]) {
            guard let value = record.rentBurdenPct else { return notReported("rent burden", county: county) }
            return answer("Rent burden", "\(value.scoreText)%",
                          "That is the share of renting households spending more than 30% of their income on rent.")
        }
        if has(q, ["rent"]) {
            guard let rent = record.medianGrossRent else { return notReported("median rent", county: county) }
            var note = "That is the midpoint monthly rent, including utilities."
            if let share = RiskScoring.rentToIncomeRatio(record) {
                note += " Over a year that is about \(share.scoreText)% of median household income."
            }
            return answer("Median gross rent",
                          rent.formatted(.currency(code: "USD").precision(.fractionLength(0))) + " a month",
                          note)
        }
        if has(q, ["poverty", "poor"]) {
            guard let value = record.povertyRate else { return notReported("poverty rate", county: county) }
            return answer("The poverty rate", "\(value.scoreText)%",
                          "That is the share of people living below the federal poverty line.")
        }
        if has(q, ["unemploy", "jobless", "out of work", "jobs"]) {
            guard let value = record.unemploymentRate else {
                return notReported("unemployment rate", county: county)
            }
            return answer("Unemployment", "\(value.scoreText)%",
                          "That is the share of the labour force out of work and looking for a job.")
        }

        // Asked for a figure but not one we hold — say which ones exist.
        return ChatAnswer(
            text: "I don't have that figure for \(county.county). What I do have: median household income, median gross rent, rent burden, the poverty rate, and the unemployment rate.",
            provenance: provenance(for: county),
            followUps: ["What is \(county.county)'s poverty rate?", "Why is \(county.county) at risk?"],
            isDecline: true
        )
    }

    private static func notReported(_ what: String, county: ScoredCounty) -> ChatAnswer {
        ChatAnswer(
            text: "The Census doesn't publish \(what) for \(county.county), so I can't give you that figure.",
            provenance: provenance(for: county),
            followUps: ["Why does \(county.county) have no score?", "Which county is highest risk?"],
            isDecline: true
        )
    }

    private static func driverScore(_ q: String, county: ScoredCounty, dataset: Dataset) -> ChatAnswer {
        let map: [(needles: [String], kind: DriverKind)] = [
            (["housing", "rent", "eviction", "landlord"], .housing),
            (["debt", "credit", "delinquen", "borrow"], .debt),
            (["cost of living", "poverty", "unemploy", "jobs", "wages"], .cost),
            (["energy", "utility", "utilities", "heating", "electric"], .energy),
            (["food", "grocery", "groceries", "hunger"], .food)
        ]
        guard let hit = map.first(where: { has(q, $0.needles) }),
              let driver = county.driver(hit.kind) else {
            return whyAtRisk(county: county, dataset: dataset)
        }

        guard driver.isMeasured else {
            return ChatAnswer(
                text: "\(hit.kind.title) isn't measured for \(county.county). This dataset has no source for it, so it's left out of the score rather than estimated.\n\n\(hit.kind.whyThisMatters)",
                provenance: provenance(for: county),
                followUps: ["What does the score include?", "Why is \(county.county) at risk?"],
                isDecline: true
            )
        }

        let standing = dataset.standings(for: county).first { $0.kind == hit.kind }
        var text = "\(hit.kind.title) scores **\(driver.score.scoreText) out of 100** for \(county.county)."
        if let standing { text += " \(standing.comparisonSentence)" }
        text += "\n\n\(hit.kind.whyThisMatters)"
        return ChatAnswer(
            text: text,
            provenance: provenance(for: county),
            followUps: ["Why is \(county.county) at risk?", "What could help \(county.county)?"]
        )
    }

    private static func whyAtRisk(county: ScoredCounty, dataset: Dataset) -> ChatAnswer {
        let standings = dataset.standings(for: county)
        guard let top = standings.first else { return decline(county: county) }
        let lines = standings.map {
            "· \($0.kind.title): \($0.score.scoreText) — \($0.severity.label.lowercased())"
        }.joined(separator: "\n")
        return ChatAnswer(
            text: """
            \(county.county) scores \(county.index?.scoreText ?? "—") overall. Ranked strongest first:

            \(lines)

            The biggest is **\(top.kind.title)**. \(top.kind.whyThisMatters)
            """,
            provenance: provenance(for: county),
            followUps: ["What could help \(county.county)?", "How does \(county.county) rank?"]
        )
    }

    private static func recommendations(_ q: String, county: ScoredCounty, dataset: Dataset) -> ChatAnswer {
        let standings = dataset.standings(for: county)
        let audience: RecommendationAudience = has(q, ["resident", "residents", "people", "families", "i live"])
            ? .residents : .policymakers
        let recs = RecommendationEngine.recommendations(for: standings, audience: audience)
        guard let first = recs.first else { return decline(county: county) }
        let actions = first.actions.prefix(3).map { "· \($0)" }.joined(separator: "\n")
        return ChatAnswer(
            text: """
            The clearest priority for \(county.county) is **\(first.driver.title)**. \(first.rationale)

            \(audience == .residents ? "Support that commonly exists:" : "Intervention areas:")
            \(actions)

            The Recommendations screen has the full list, for policymakers and for residents.
            """,
            provenance: provenance(for: county),
            followUps: ["Why is \(county.county) at risk?", "What could residents do?"]
        )
    }

    private static func rank(county: ScoredCounty, dataset: Dataset) -> ChatAnswer {
        guard let rank = dataset.rank(of: county),
              let percentile = dataset.percentile(for: county),
              let index = county.index else {
            return unscoredExplanation(county)
        }
        return ChatAnswer(
            text: "**\(county.displayName)** ranks **\(rank.formatted(.number)) of \(dataset.scoredCounties.count.formatted(.number))** counties by financial distress, with an index of \(index.scoreText) — a higher score than \(PercentilePhrasing.shareOfThem(percentile)).",
            provenance: provenance(for: county),
            followUps: ["Why is \(county.county) at risk?", "Which county is highest risk?"]
        )
    }

    private static func unscoredExplanation(_ county: ScoredCounty) -> ChatAnswer {
        ChatAnswer(
            text: """
            **\(county.displayName)** has no score. The Census doesn't publish enough data for it — this happens in counties with very small populations.

            Missing: \(ListFormatter.localizedString(byJoining: county.missingIndicators)).

            No score is not the same as low risk. It means this county can't be measured here.
            """,
            provenance: provenance(for: county),
            followUps: ["Which county is highest risk?", "How is the score worked out?"]
        )
    }

    // MARK: - Comparison

    private static func comparison(
        _ q: String,
        question: String,
        dataset: Dataset,
        searchIndex: CountySearchIndex
    ) -> ChatAnswer? {
        let separators = [" vs ", " versus ", " compared to ", " against ", " or "]
        var parts: [String]?
        for separator in separators where q.contains(separator) {
            parts = q.components(separatedBy: separator)
            break
        }
        if parts == nil, q.hasPrefix("compare "), q.contains(" and ") {
            let body = String(q.dropFirst("compare ".count))
            if let range = body.range(of: " and ", options: .backwards) {
                parts = [String(body[..<range.lowerBound]), String(body[range.upperBound...])]
            }
        }
        guard let parts, parts.count == 2 else { return nil }

        let first = searchIndex.mentionedCounty(in: parts[0])
            ?? searchIndex.results(for: parts[0], limit: 1).counties.first
        let second = searchIndex.mentionedCounty(in: parts[1])
            ?? searchIndex.results(for: parts[1], limit: 1).counties.first

        guard let a = first, let b = second else {
            let unknown = (first == nil ? parts[0] : parts[1]).trimmingCharacters(in: .whitespaces)
            return ChatAnswer(
                text: "I couldn't find a county matching \"\(unknown)\". Try a county name, a state, or both — for example \"Cook, Illinois\".",
                isDecline: true
            )
        }
        guard let indexA = a.index, let indexB = b.index else {
            let unscored = a.index == nil ? a : b
            return ChatAnswer(
                text: "\(unscored.displayName) has no score, so I can't compare it. The Census doesn't publish enough data for it.",
                provenance: "\(a.displayName) and \(b.displayName)",
                isDecline: true
            )
        }

        let higher = indexA > indexB ? a : b
        let lower = indexA > indexB ? b : a
        let gap = abs(indexA - indexB)
        let text = """
        **\(a.displayName)** scores \(indexA.scoreText) — \(a.riskLevel?.label.lowercased() ?? "no") risk.
        **\(b.displayName)** scores \(indexB.scoreText) — \(b.riskLevel?.label.lowercased() ?? "no") risk.

        \(gap < 0.05 ? "They are effectively level." : "\(higher.county) is under more financial pressure, by \(gap.scoreText) points.")
        """
        return ChatAnswer(
            text: text,
            provenance: "\(a.displayName) and \(b.displayName) · U.S. Census ACS 5-Year",
            followUps: ["Why is \(higher.county) at risk?", "Why is \(lower.county) lower?"]
        )
    }

    // MARK: - Shared description

    /// Every figure interpolated from live values — nothing written by hand.
    private static func describe(_ county: ScoredCounty, in dataset: Dataset) -> String {
        guard let index = county.index, let level = county.riskLevel else {
            return "**\(county.displayName)** has no score — the Census doesn't publish enough data for it."
        }
        var text = "**\(county.displayName)** scores \(index.scoreText) out of 100 — \(level.label.lowercased()) risk."
        if let rank = dataset.rank(of: county), let percentile = dataset.percentile(for: county) {
            text += " That ranks \(rank.formatted(.number)) of \(dataset.scoredCounties.count.formatted(.number)) counties, a higher score than \(PercentilePhrasing.shareOfThem(percentile))."
        }
        if let top = dataset.standings(for: county).first {
            text += "\n\nIts strongest pressure is **\(top.kind.title)** at \(top.score.scoreText). \(top.comparisonSentence)"
        }
        return text
    }

    // MARK: - Quick prompts

    static func quickPrompts(for county: ScoredCounty?) -> [String] {
        guard let county else {
            return [
                "Which county is highest risk?",
                "How many counties are high risk?",
                "How is the score worked out?",
                "What can you do?"
            ]
        }
        guard county.isScored else {
            return [
                "Why does \(county.county) have no score?",
                "How is the score worked out?",
                "Which county is highest risk?"
            ]
        }
        return [
            "Why is \(county.county) at risk?",
            "What could help \(county.county)?",
            "What is \(county.county)'s poverty rate?",
            "How does \(county.county) rank?",
            "How is the score worked out?"
        ]
    }
}
