import Foundation

/// Ask DebtShield, re-pointed at the person.
///
/// The county `ChatEngine` explained a place. This explains *your month*, from
/// the numbers you entered — and nothing else. Like its predecessor it is a
/// deterministic responder, not a language model: it computes every dollar it
/// quotes from `MoneyPlan` at the moment it answers, so it can never invent a
/// figure about your money.
///
/// ## The boundary
///
/// It will **explain** (why you're short, where your money goes) and **suggest**
/// (which cost is the biggest lever, what a change would do). It will not
/// **advise**: anything about taking a loan, consolidating, bankruptcy, benefits
/// eligibility, or investing is turned away — warmly — toward real, free human
/// help. The old engine refused *every* personal question; this one draws the
/// line in a different, and much more useful, place.
///
/// ## Voice
///
/// Calm, plain, never shaming. No "risk", no score, no grade. It talks in
/// dollars and in the second person, and when money is tight it says so gently
/// and points at what can actually be changed.
enum PersonalChatEngine {

    // MARK: - Entry point

    static func respond(
        to question: String,
        plan: MoneyPlan,
        county: ScoredCounty? = nil,
        benchmarks: Benchmarks? = nil
    ) -> ChatAnswer {
        let q = normalise(question)
        guard !q.isEmpty else { return opening(for: plan) }

        // Advice territory is turned away before anything else.
        if let redirect = adviceRedirect(q) { return redirect }

        // "What if …" works on the entered numbers.
        if let whatIf = whatIf(q, plan: plan) { return whatIf }

        // The safe line can be explained even before numbers are entered.
        if has(q, ["safe line", "safeline", "the line", "55", "fifty five", "fifty-five"]) {
            return safeLineExplanation(plan)
        }

        // "How does my rent compare / is my energy high" — uses the county and
        // national reference data, the same numbers the Compare tab shows.
        if let comparison = comparisonAnswer(q, plan: plan, county: county, benchmarks: benchmarks) {
            return comparison
        }

        // Everything else needs the numbers.
        guard plan.isComplete else { return needNumbers() }

        if has(q, ["why", "how come", "reason"]) {
            return whyExplanation(plan)
        }
        if has(q, ["fastest", "quickest", "fix", "cut", "reduce", "trim", "lower",
                   "free up", "save", "what can i do", "what should i do",
                   "where do i start", "help me", "get ahead", "room"]) {
            return fastestFix(plan)
        }
        if has(q, ["biggest", "largest", "most expensive", "highest", "what costs",
                   "where does my money", "where is my money", "wheres my money",
                   "spending most", "where it goes", "goes"]) {
            return biggestCost(plan)
        }
        if has(q, ["how much", "left", "how am i", "am i okay", "am i ok",
                   "am i alright", "doing", "this month", "summary", "overview",
                   "status", "hows my", "how's my", "afford"]) {
            return statusSummary(plan)
        }

        // Gentle default: just tell them where they stand.
        return statusSummary(plan)
    }

    // MARK: - Quick prompts

    static func quickPrompts(for plan: MoneyPlan) -> [String] {
        guard plan.isComplete else {
            return ["What's the safe line?", "What can this tell me?"]
        }
        var prompts = ["Why is it tight?", "How does my rent compare?", "What's my fastest fix?"]
        if let biggest = biggestSegment(plan) {
            prompts.append("What if \(biggest.label.lowercased()) dropped $100?")
        }
        prompts.append("How do all my costs compare?")
        return prompts
    }

    static func opening(for plan: MoneyPlan) -> ChatAnswer {
        if plan.isComplete {
            return ChatAnswer(
                text: "Ask me about your month. I'll explain it from the numbers you entered — why things are tight, where your money goes, what would free up the most, and how your costs compare to your area and the rest of the U.S.",
                followUps: quickPrompts(for: plan)
            )
        }
        return ChatAnswer(
            text: "Once you add your numbers on the home screen, I can explain your month in plain dollars. I can still tell you how the safe line works in the meantime.",
            followUps: quickPrompts(for: plan)
        )
    }

    // MARK: - Comparison (integrates the county + national data)

    /// Answers "how does my rent compare", "is my energy bill high", "how do I
    /// compare to everyone else" — from the same `CostComparisons` the Compare
    /// tab uses. Returns nil when the question isn't about comparing.
    private static func comparisonAnswer(
        _ q: String,
        plan: MoneyPlan,
        county: ScoredCounty?,
        benchmarks: Benchmarks?
    ) -> ChatAnswer? {
        let markers = ["compare", "comparison", "typical", "average", "normal",
                       "than most", "than everyone", "than others", "everyone else",
                       "national", "nationally", "my area", "the area", "vs ", "versus",
                       "too much", "too high", "too low", "higher", "lower than",
                       "is my rent high", "is my", "how much do others", "how do i stack"]
        guard has(q, markers) else { return nil }
        guard plan.isComplete else { return needNumbers() }

        let comps = CostComparisons.all(plan: plan, county: county, benchmarks: benchmarks)
        guard !comps.isEmpty else {
            return ChatAnswer(
                text: "I can compare your costs to what's typical once the numbers are in. Add where you live on the Compare tab to include your local rent and energy.",
                followUps: ["What's the safe line?"],
                isDecline: true
            )
        }

        // A specific cost named in the question wins.
        if let kind = category(in: q), let match = comps.first(where: { $0.kind == kind }) {
            return describeOne(match)
        }
        return overallComparison(comps)
    }

    private static func describeOne(_ c: Comparison) -> ChatAnswer {
        var text = "Your \(c.kind.label.lowercased()) is **\(money(c.yours))** a month.\n\n"
        for ref in c.refs {
            text += "· \(ref.label): \(money(ref.amount))\n"
        }
        text += "\n\(c.verdict)"
        return ChatAnswer(
            text: text,
            provenance: "Your numbers vs \(c.source)",
            followUps: ["How do all my costs compare?", "What's my fastest fix?"]
        )
    }

    private static func overallComparison(_ comps: [Comparison]) -> ChatAnswer {
        let lines = comps.map { c -> String in
            let ref = c.refs.first
            let refText = ref.map { " vs \(money($0.amount)) \($0.label.lowercased())" } ?? ""
            return "· \(c.kind.label): \(money(c.yours))\(refText) — \(standingWord(c.standing))"
        }.joined(separator: "\n")

        let highs = comps.filter { $0.standing == .above || $0.standing == .high }.map { $0.kind.label.lowercased() }
        let closer = highs.isEmpty
            ? "Nothing's standing out as high — you're close to or below typical across the board."
            : "Running higher than most: \(ListFormatter.localizedString(byJoining: highs)). That's just where to look first."

        return ChatAnswer(
            text: "Here's how your costs line up with typical:\n\n\(lines)\n\n\(closer)",
            provenance: "Your numbers vs Census, EIA, BLS",
            followUps: ["What's my fastest fix?", "Why is it tight?"]
        )
    }

    private static func standingWord(_ standing: CostStanding) -> String {
        switch standing {
        case .above: return "higher than most"
        case .about: return "about typical"
        case .below: return "lower than most"
        case .healthy: return "comfortable"
        case .watch: return "a bit high"
        case .high: return "high"
        }
    }

    // MARK: - Advice redirect

    /// Real advice — loans, bankruptcy, benefits, investing, legal. Turned away
    /// gently, toward free human help. Non-shaming and specific.
    private static func adviceRedirect(_ q: String) -> ChatAnswer? {
        let markers = [
            "loan", "borrow", "consolidat", "refinanc", "balance transfer",
            "payday", "credit card should", "which card", "open a card",
            "bankrupt", "chapter 7", "chapter 13", "sue", "lawyer", "legal",
            "qualify for", "eligible", "food stamps", "snap", "medicaid",
            "unemployment benefit", "apply for", "invest", "stocks", "crypto",
            "401k", "roth", "retirement account"
        ]
        guard has(q, markers) else { return nil }
        return ChatAnswer(
            text: """
            That's a real decision, and it deserves a real person — not an app. I can show you where your money stands, but I'm not the right place for advice on loans, benefits, or the legal side of debt.

            Two good, free options:
            · **211** — call or visit 211.org to reach local help with rent, food, and bills.
            · **HUD-approved counsellors** — free, one-on-one money and housing guidance. Find one at hud.gov.

            When you're ready, ask me why your month is tight or what would free up the most — I can help with that part.
            """,
            followUps: ["Why is it tight?", "What's my fastest fix?"],
            isDecline: true
        )
    }

    // MARK: - Explanations

    private static func whyExplanation(_ plan: MoneyPlan) -> ChatAnswer {
        guard let income = plan.monthlyIncome, let left = plan.moneyLeft,
              let share = plan.essentialsShare, let status = plan.status,
              let biggest = biggestSegment(plan) else {
            return needNumbers()
        }
        let essentials = plan.essentialsTotal
        let sharePct = percent(share)

        var text: String
        switch status {
        case .over:
            let over = money(-left)
            text = "This month your essentials come to \(money(essentials)), but only \(money(income)) is coming in — that's \(over) more going out than in. The biggest single piece is **\(biggest.label.lowercased())** at \(money(biggest.amount))."
        case .tight:
            text = "Your essentials add up to \(money(essentials)) — that's \(sharePct) of your \(money(income)) income, a bit past the safe line of \(percent(MoneyPlan.safeLineShare)). You've got \(money(left)) left, so it works, but there isn't much slack. The biggest piece is **\(biggest.label.lowercased())** at \(money(biggest.amount))."
        case .okay:
            text = "You're okay this month. Essentials are \(money(essentials)) — \(sharePct) of your \(money(income)) income, under the safe line — leaving you \(money(left)). Your biggest cost is **\(biggest.label.lowercased())** at \(money(biggest.amount))."
        }
        return ChatAnswer(
            text: text,
            provenance: "Your numbers",
            followUps: ["What's my fastest fix?", "What if \(biggest.label.lowercased()) dropped $100?"]
        )
    }

    private static func biggestCost(_ plan: MoneyPlan) -> ChatAnswer {
        guard let income = plan.monthlyIncome, let biggest = biggestSegment(plan) else {
            return needNumbers()
        }
        let shareOfIncome = income > 0 ? percent(biggest.amount / income) : "—"
        let ordered = plan.segments.sorted { $0.amount > $1.amount }
        let rest = ordered.dropFirst().prefix(2)
            .map { "\($0.label.lowercased()) \(money($0.amount))" }
            .joined(separator: ", ")
        var text = "Your biggest cost is **\(biggest.label.lowercased())** at \(money(biggest.amount)) a month — about \(shareOfIncome) of your income."
        if !rest.isEmpty { text += "\n\nAfter that: \(rest)." }
        return ChatAnswer(
            text: text,
            provenance: "Your numbers",
            followUps: ["What's my fastest fix?", "Why is it tight?"]
        )
    }

    private static func fastestFix(_ plan: MoneyPlan) -> ChatAnswer {
        guard let biggest = biggestSegment(plan) else { return needNumbers() }

        var text = "The single biggest thing you pay is **\(biggest.label.lowercased())**, at \(money(biggest.amount)) a month. Because it's your largest cost, a change there frees up the most — even \(money(50)) less is \(money(50)) back in your pocket this month."

        // Rent and mortgage rarely move quickly, so point at the largest cost
        // that usually can, as the practical lever.
        if biggest.kind == .housing {
            let movable = plan.segments
                .filter { $0.kind != .housing }
                .max { $0.amount < $1.amount }
            if let movable {
                text += "\n\nRent or a mortgage is the hardest to change fast, so the quickest place to start is often **\(movable.label.lowercased())** at \(money(movable.amount)) — usually easier to trim month to month."
            }
        }

        text += "\n\nSmall and steady beats a big one-off. Try a \(money(50))–\(money(100)) change and see how the bar moves."
        return ChatAnswer(
            text: text,
            provenance: "Your numbers",
            followUps: ["What if \(biggest.label.lowercased()) dropped $100?", "What's my biggest cost?"]
        )
    }

    private static func statusSummary(_ plan: MoneyPlan) -> ChatAnswer {
        guard let left = plan.moneyLeft, let status = plan.status else { return needNumbers() }
        let text: String
        switch status {
        case .okay:
            text = "You're okay this month — **\(money(left)) left** after essentials. There's room to breathe."
        case .tight:
            text = "It's tight this month, but it works: **\(money(left)) left** after essentials. Not much slack, so worth keeping an eye on."
        case .over:
            text = "Money's tight this month — you're **\(money(-left)) short** after essentials. That's worth looking at, and I can show you where the biggest lever is."
        }
        return ChatAnswer(
            text: text,
            provenance: "Your numbers",
            followUps: ["Why is it tight?", "What's my fastest fix?"]
        )
    }

    private static func safeLineExplanation(_ plan: MoneyPlan) -> ChatAnswer {
        let linePct = percent(MoneyPlan.safeLineShare)
        var text = "The safe line is a simple guide: try to keep your essentials — rent, food, energy, debt payments — under \(linePct) of what comes in. Below it, you've usually got room for everything else and a bit to save. Past it, the month gets tight fast."
        if let income = plan.monthlyIncome, let safe = plan.safeLineAmount, income > 0 {
            text += "\n\nFor your \(money(income)) income, that line sits at about \(money(safe)) of essentials."
            if let share = plan.essentialsShare {
                text += share <= MoneyPlan.safeLineShare
                    ? " You're under it — nice."
                    : " Right now you're a little over it, at \(percent(share))."
            }
        }
        return ChatAnswer(
            text: text,
            provenance: plan.monthlyIncome == nil ? nil : "Your numbers",
            followUps: plan.isComplete ? ["Why is it tight?", "What's my fastest fix?"] : ["What can this tell me?"]
        )
    }

    // MARK: - What if

    private static func whatIf(_ q: String, plan: MoneyPlan) -> ChatAnswer? {
        guard has(q, ["what if", "if i", "if my", "if rent", "if we", "suppose",
                      "imagine", "what would", "what happens if"]) else { return nil }
        guard let amount = firstAmount(in: q) else { return nil }
        guard plan.isComplete, let beforeLeft = plan.moneyLeft else { return needNumbers() }

        let decrease = has(q, ["drop", "less", "lower", "cut", "reduce", "down", "save",
                               "cheaper", "without", "fell", "fall", "decreas", "paid off",
                               "pay off", "gone", "no more"])
        let increase = has(q, ["more", "raise", "higher", "increas", "up ", "extra",
                               "gain", "add", "went up", "goes up"])
        let sign: Double = (increase && !decrease) ? 1 : -1

        var modified = plan
        let label: String
        if let kind = category(in: q) {
            let current = value(of: kind, in: plan) ?? 0
            set(kind, to: max(0, current + sign * amount), in: &modified)
            label = kind.label.lowercased()
        } else if touchesIncome(q) {
            modified.monthlyIncome = max(0, (plan.monthlyIncome ?? 0) + sign * amount)
            label = "income"
        } else {
            return nil // couldn't tell what to change — fall through to other intents
        }

        guard let afterLeft = modified.moneyLeft, let afterStatus = modified.status else {
            return needNumbers()
        }

        let direction = sign > 0 ? "went up" : "dropped"
        let diff = afterLeft - beforeLeft
        var text = "If \(label) \(direction) by \(money(amount)):\n\nYou'd have **\(signedLeft(afterLeft))** \(afterLeft >= 0 ? "left" : "short") this month, instead of \(signedLeft(beforeLeft)). That's \(money(abs(diff))) \(diff >= 0 ? "more" : "less") room."

        // Note a crossing of the safe line or of zero — the moments that matter.
        if let beforeStatus = plan.status, beforeStatus != afterStatus {
            switch afterStatus {
            case .okay: text += "\n\nThat would bring you back under the safe line."
            case .tight where beforeStatus == .over: text += "\n\nThat would cover the month again, though it'd still be tight."
            case .tight: text += "\n\nThat would nudge you past the safe line."
            case .over: text += "\n\nThat would tip the month into the red."
            }
        }
        return ChatAnswer(
            text: text,
            provenance: "Your numbers, adjusted",
            followUps: ["What's my fastest fix?", "Why is it tight?"]
        )
    }

    private static func needNumbers() -> ChatAnswer {
        ChatAnswer(
            text: "I need your numbers first. Add your income and monthly essentials on the home screen, then I can explain your month in plain dollars.",
            followUps: ["What's the safe line?"],
            isDecline: true
        )
    }

    // MARK: - Segment helpers

    private static func biggestSegment(_ plan: MoneyPlan) -> EssentialSegment? {
        plan.segments.max { $0.amount < $1.amount }
    }

    private static func value(of kind: EssentialKind, in plan: MoneyPlan) -> Double? {
        switch kind {
        case .housing: return plan.housing
        case .food: return plan.food
        case .energy: return plan.energy
        case .debt: return plan.debtPayments
        }
    }

    private static func set(_ kind: EssentialKind, to newValue: Double, in plan: inout MoneyPlan) {
        switch kind {
        case .housing: plan.housing = newValue
        case .food: plan.food = newValue
        case .energy: plan.energy = newValue
        case .debt: plan.debtPayments = newValue
        }
    }

    private static func category(in q: String) -> EssentialKind? {
        if has(q, ["rent", "mortgage", "housing", "apartment", "landlord"]) { return .housing }
        if has(q, ["food", "grocer", "groceries", "eating", "meals"]) { return .food }
        if has(q, ["energy", "utilit", "electric", "heating", "power bill", "gas bill", "bills"]) { return .energy }
        if has(q, ["debt", "loan payment", "card payment", "minimum", "credit card payment", "payments"]) { return .debt }
        return nil
    }

    private static func touchesIncome(_ q: String) -> Bool {
        has(q, ["income", "paycheck", "salary", "earn", "made", "make more",
                "wage", "raise", "pay went", "got a raise", "more pay"])
    }

    // MARK: - Number extraction

    /// The first dollar figure in the sentence. Handles "$1,200", "1200",
    /// "1.2k", "200".
    private static func firstAmount(in q: String) -> Double? {
        let chars = Array(q)
        var i = 0
        while i < chars.count {
            guard chars[i].isNumber else { i += 1; continue }
            var j = i
            var digits = ""
            while j < chars.count, chars[j].isNumber || chars[j] == "," || chars[j] == "." {
                if chars[j] != "," { digits.append(chars[j]) }
                j += 1
            }
            guard var value = Double(digits) else { return nil }
            if j < chars.count, chars[j] == "k" { value *= 1_000 }
            return value
        }
        return nil
    }

    // MARK: - Text + formatting

    static func normalise(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func has(_ q: String, _ needles: [String]) -> Bool {
        needles.contains { q.contains($0) }
    }

    private static func money(_ value: Double) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }

    /// Money left, showing a leading minus when negative.
    private static func signedLeft(_ value: Double) -> String {
        let magnitude = money(abs(value))
        return value >= 0 ? magnitude : "−\(magnitude)"
    }

    private static func percent(_ share: Double) -> String {
        "\(Int((share * 100).rounded()))%"
    }
}
