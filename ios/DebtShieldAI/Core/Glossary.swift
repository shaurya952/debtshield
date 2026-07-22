import Foundation

/// One glossary entry.
struct GlossaryTerm: Identifiable, Sendable {
    let term: String
    /// One or two sentences, no jargon and no assumed background.
    let definition: String
    /// Optional concrete illustration. Kept generic — never a real county's
    /// figures, because an example that looks like data would read as data.
    let example: String?
    let category: Category

    var id: String { term }

    enum Category: String, CaseIterable, Identifiable, Sendable {
        case scores = "Scores and risk"
        case indicators = "What we measure"
        case tools = "Tools in this app"

        var id: String { rawValue }
    }
}

enum Glossary {

    static let terms: [GlossaryTerm] = [

        // MARK: Scores and risk

        GlossaryTerm(
            term: "Financial Distress Index",
            definition: "A single score from 0 to 100 that summarises how much financial pressure a county is under. Higher means more pressure. It is worked out with a fixed formula, so the same figures always produce the same score.",
            example: "A county scoring 20 is under less pressure than one scoring 60.",
            category: .scores
        ),
        GlossaryTerm(
            term: "Risk level",
            definition: "A plain-language band for the index. Below 35 is low, 35 up to 65 is medium, and 65 or above is high. The bands make the number easier to talk about; they are not official designations.",
            example: nil,
            category: .scores
        ),
        GlossaryTerm(
            term: "Risk drivers",
            definition: "The separate pressures that add up to the index — housing, cost of living, debt, energy, and food access. Each is scored 0 to 100 on its own, so you can see which one is pushing a county's overall score up.",
            example: "Two counties can share a score of 40 for completely different reasons.",
            category: .scores
        ),

        // MARK: What we measure

        GlossaryTerm(
            term: "Rent burden",
            definition: "The share of renting households that spend more than 30% of their income on rent. Thirty percent is the long-standing benchmark for housing being affordable.",
            example: "A rent burden of 45% means nearly half of renters are over that line.",
            category: .indicators
        ),
        GlossaryTerm(
            term: "Poverty rate",
            definition: "The share of people living below the federal poverty line — an income threshold the U.S. government sets each year, adjusted for household size.",
            example: nil,
            category: .indicators
        ),
        GlossaryTerm(
            term: "Unemployment rate",
            definition: "The share of people in the labour force who are out of work and looking for a job. People who are not looking for work are not counted in it.",
            example: nil,
            category: .indicators
        ),
        GlossaryTerm(
            term: "Debt-to-income ratio",
            definition: "How much a household owes compared with what it earns in a year. A ratio of 1.5 means debts are one and a half times annual income.",
            example: "Higher ratios leave less room to absorb an unexpected bill.",
            category: .indicators
        ),
        GlossaryTerm(
            term: "Credit delinquency",
            definition: "A payment that is overdue — usually 30, 60, or 90 days late. A delinquency rate is the share of accounts in that position, and it is an early sign of households falling behind.",
            example: nil,
            category: .indicators
        ),
        GlossaryTerm(
            term: "Energy burden",
            definition: "The share of household income spent on heating, cooling, and electricity. A high energy burden means utility bills are competing with rent and food.",
            example: "Spending 10% of income on energy is generally considered a high burden.",
            category: .indicators
        ),
        GlossaryTerm(
            term: "Food access",
            definition: "How easily people on low incomes can reach an affordable, well-stocked grocery store. Poor food access usually means distance, no transport, or no full-service store nearby.",
            example: nil,
            category: .indicators
        ),

        // MARK: Tools

        GlossaryTerm(
            term: "Scenario simulator",
            definition: "A tool that recalculates a county's index after you change figures such as income or the poverty rate. It shows what the score would be under those numbers. It does not predict that they will change.",
            example: nil,
            category: .tools
        ),
        GlossaryTerm(
            term: "Model performance",
            definition: "A record of how well some machine-learning models reproduced the risk labels during research. These models do not power the app — the index is a fixed formula — and the screen explains what those scores do and do not show.",
            example: nil,
            category: .tools
        )
    ]

    /// Case- and accent-insensitive search across term and definition.
    static func search(_ query: String) -> [GlossaryTerm] {
        let needle = query
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return terms }
        return terms.filter { term in
            let haystack = "\(term.term) \(term.definition)"
                .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            return haystack.contains(needle)
        }
    }

    static func terms(in category: GlossaryTerm.Category, matching query: String) -> [GlossaryTerm] {
        search(query).filter { $0.category == category }
    }
}
