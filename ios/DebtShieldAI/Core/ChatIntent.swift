import Foundation

/// What a question is asking for.
///
/// The first version of the chatbot walked a fixed `if` chain and answered on
/// the first keyword hit, which meant question order decided the answer and
/// anything phrased unusually fell straight through to a decline. This scores
/// every intent against the question and picks the strongest, so "what's the
/// poverty rate in Cook County" and "how poor is Cook County" land in the same
/// place.
enum ChatIntent: String, CaseIterable, Sendable {
    case greeting
    case capabilities
    case define
    case methodology
    case riskLevelMeaning
    case dataSource
    case privacy
    case summary
    case indicator
    case driverScore
    case whyAtRisk
    case recommendations
    case compare
    case extremes
    case counts
    case nationalAverage
    case stateSummary
    case stateRanking
    case rank

    /// Multi-word phrases. A hit here is strong evidence.
    var phrases: [String] {
        switch self {
        case .greeting:
            return ["hello", "hi there", "hey there", "good morning", "good afternoon", "good evening"]
        case .capabilities:
            return ["what can you do", "what can i ask", "what do you know", "how can you help",
                    "what are you", "who are you", "help me understand", "what questions"]
        case .define:
            return ["what is a", "what is the", "what does", "what are", "define", "meaning of",
                    "explain what", "tell me what"]
        case .methodology:
            return ["how is the score", "how do you score", "how is it calculated", "how is this calculated",
                    "how does it work", "how do you work it out", "financial distress index",
                    "how is the index", "what goes into", "methodology", "how are counties scored"]
        case .riskLevelMeaning:
            return ["what does low risk mean", "what does medium risk mean", "what does high risk mean",
                    "what does moderate risk mean", "mean by low risk", "mean by high risk",
                    "what counts as high risk", "what makes a county high risk"]
        case .dataSource:
            return ["where does the data", "where is the data", "what data do you", "how recent",
                    "how old is the data", "who collects", "is this real data", "data source",
                    "where do these numbers"]
        case .privacy:
            return ["do you collect", "is my data", "do you track", "what do you store",
                    "is this private", "do you send", "do you share my"]
        case .summary:
            return ["tell me about", "give me a summary", "summarise", "summarize", "overview of",
                    "how is this county", "how bad is", "how is it doing", "what about"]
        case .indicator:
            return ["poverty rate", "unemployment rate", "median income", "household income",
                    "rent burden", "median rent", "how much rent", "how many people are poor",
                    "how much do people earn", "how many are unemployed", "cost of rent"]
        case .driverScore:
            return ["housing score", "debt score", "energy score", "food score",
                    "cost of living score", "housing pressure", "housing stress"]
        case .whyAtRisk:
            return ["why is", "why are", "what is driving", "what drives", "what is causing",
                    "what causes", "biggest factor", "main problem", "what pushes", "what makes it",
                    "reason for", "the cause"]
        case .recommendations:
            return ["what should be done", "what could help", "what would help", "what can be done",
                    "how to fix", "how do we fix", "what support", "what programmes", "what programs",
                    "what assistance", "what is available", "policy options", "what should policymakers",
                    "what should residents", "how to improve", "what interventions"]
        case .compare:
            return ["compare", "versus", " vs ", "compared to", "against", "which is worse",
                    "which is better", "difference between"]
        case .extremes:
            return ["riskiest", "highest risk", "worst county", "most at risk", "worst off",
                    "safest", "lowest risk", "least at risk", "best county", "best off",
                    "top 10", "top ten", "worst counties", "best counties"]
        case .counts:
            return ["how many counties", "how many are", "how many high risk", "how many medium",
                    "how many low risk", "number of counties", "how many states", "how many have"]
        case .nationalAverage:
            return ["national average", "average index", "average score", "average across",
                    "typical county", "what is normal", "average county"]
        case .stateSummary:
            return ["how is the state", "about the state", "state average", "how is my state"]
        case .stateRanking:
            return ["which state", "worst state", "best state", "states ranked", "worst states",
                    "which states are"]
        case .rank:
            return ["what rank", "where does it rank", "how does it rank", "ranked", "ranking of",
                    "compared to other counties", "compared to the rest"]
        }
    }

    /// Single words. Weaker evidence, used to break ties.
    var keywords: [String] {
        switch self {
        case .greeting: return ["hello", "hi", "hey"]
        case .capabilities: return ["help", "commands", "options"]
        case .define: return ["define", "definition", "meaning", "means"]
        case .methodology: return ["calculated", "formula", "weights", "weighted", "methodology", "index"]
        case .riskLevelMeaning: return []
        case .dataSource: return ["census", "acs", "source", "sources", "survey"]
        case .privacy: return ["privacy", "private", "tracking", "stored", "collect"]
        case .summary: return ["summary", "overview", "about"]
        case .indicator: return ["income", "earn", "salary", "wages", "rent", "poverty", "poor",
                                 "unemployment", "unemployed", "jobless", "jobs"]
        case .driverScore: return ["housing", "debt", "energy", "utilities", "food", "grocery", "groceries"]
        case .whyAtRisk: return ["why", "driver", "drivers", "cause", "causes", "reason", "because"]
        case .recommendations: return ["help", "fix", "improve", "action", "actions", "solution",
                                       "solutions", "recommend", "recommendations", "priority",
                                       "prioritise", "prioritize", "policy", "support", "assistance"]
        case .compare: return ["compare", "vs", "versus", "difference"]
        case .extremes: return ["riskiest", "safest", "worst", "best", "highest", "lowest"]
        case .counts: return ["many", "count", "number", "total"]
        case .nationalAverage: return ["average", "mean", "typical", "normal"]
        case .stateSummary: return ["state"]
        case .stateRanking: return ["states"]
        case .rank: return ["rank", "ranked", "ranking", "position", "place"]
        }
    }

    /// Scores this intent against a normalised question.
    func score(_ question: String) -> Int {
        var total = 0
        for phrase in phrases where question.contains(phrase) {
            total += 6
        }
        let words = Set(question.split(separator: " ").map(String.init))
        for keyword in keywords where words.contains(keyword) {
            total += 2
        }
        return total
    }

    /// Picks the strongest intent, or nil when nothing is convincing.
    static func best(for question: String) -> ChatIntent? {
        let scored = allCases
            .map { (intent: $0, score: $0.score(question)) }
            .filter { $0.score > 0 }
            .sorted { $0.score > $1.score }
        guard let top = scored.first, top.score >= 2 else { return nil }
        return top.intent
    }
}
