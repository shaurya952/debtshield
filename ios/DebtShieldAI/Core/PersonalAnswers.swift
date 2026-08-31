import Foundation

/// Ask Headroom, re-pointed at the person.
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
        benchmarks: Benchmarks? = nil,
        months: [MonthRecord] = []
    ) -> ChatAnswer {
        let q = normalise(question)
        guard !q.isEmpty else { return opening(for: plan) }

        // Advice territory is turned away before anything else.
        if let redirect = adviceRedirect(q) { return redirect }

        // "What are the odds I go into debt" — the Monte Carlo simulation.
        if let odds = oddsAnswer(q, plan: plan, months: months) { return odds }

        // "Where is this heading / am I going into debt" — the synthesized
        // verdict. Checked before "what if" so "will I be short next month"
        // reads as a situation question, not a hypothetical.
        if let heading = situationAnswer(q, plan: plan, months: months) { return heading }

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

        // Specific money questions, checked before the general keyword buckets.
        if let debt = debtBurdenAnswer(q, plan: plan) { return debt }
        if let cushion = cushionAnswer(q, plan: plan) { return cushion }
        if let savings = savingsRateAnswer(q, plan: plan) { return savings }
        if let annual = annualAnswer(q, plan: plan) { return annual }
        // "How much do I spend on transportation / personal / water …"
        if let category = categorySpendAnswer(q, plan: plan) { return category }

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

        // Nothing matched. Rather than answer a question it didn't understand
        // (which reads as a random reply), decline honestly and point at what it
        // *can* answer. Stays deterministic — never invents an answer.
        return gracefulFallback(plan)
    }

    /// A direct read of one category the person entered — "how much do I spend
    /// on transportation / personal / water / home upkeep?"
    private static func categorySpendAnswer(_ q: String, plan: MoneyPlan) -> ChatAnswer? {
        guard let kind = category(in: q) else { return nil }
        // Only when they're actually asking about that cost's size.
        guard has(q, ["how much", "what do i", "what am i", "spend", "cost", "costs",
                      "pay", "paying", "goes to", "go to", "my " + kind.label.lowercased()]) else { return nil }

        guard let amount = value(of: kind, in: plan), amount > 0 else {
            return ChatAnswer(
                text: "You haven't entered anything for \(kind.label.lowercased()) yet. Add it on the home screen and I'll fold it into your month.",
                provenance: "Your numbers",
                isDecline: true
            )
        }
        var text = "You put \(money(amount)) a month toward \(kind.label.lowercased())."
        if let income = plan.monthlyIncome, income > 0 {
            let pct = Int((amount / income * 100).rounded())
            text += " That's about \(pct)% of your income."
        }
        text += " (\(kind.info))"
        return ChatAnswer(text: text, provenance: "Your numbers", followUps: quickPrompts(for: plan))
    }

    /// When no intent matched: say so plainly and offer what it can do. A
    /// decline, so it carries no figures.
    private static func gracefulFallback(_ plan: MoneyPlan) -> ChatAnswer {
        ChatAnswer(
            text: "I answer only from the numbers you've entered, and I didn't quite catch that one. I can tell you where your month stands, why it's tight, where your money goes, what would free up the most, your odds for the year ahead, and how your costs compare to your area and the U.S. — try one of these:",
            provenance: "Your numbers, on this device",
            followUps: quickPrompts(for: plan),
            isDecline: true
        )
    }

    // MARK: - Quick prompts

    static func quickPrompts(for plan: MoneyPlan) -> [String] {
        guard plan.isComplete else {
            return ["What's the safe line?", "What can this tell me?"]
        }
        // Suggested chips stay neutral and answerable — we don't hand someone an
        // unprompted "odds of going into debt"; the year-ahead odds are still there
        // if they ask for them.
        var prompts = ["Why is it tight?", "Where does my money go?", "How does my rent compare?"]
        if (plan.moneyLeft ?? 0) > 0 {
            prompts.append("How's my cushion?")
        }
        if let debt = plan.debtPayments, debt > 0 {
            prompts.append("How much goes to debt?")
        }
        if let biggest = biggestSegment(plan) {
            prompts.append("What if \(biggest.label.lowercased()) dropped $100?")
        }
        prompts.append("What's my fastest fix?")
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

    // MARK: - Odds (the Monte Carlo simulation)

    /// "What are the odds / how likely am I to go into debt" — answered with the
    /// probability from `MonteCarloEngine`. `months` includes the current month,
    /// so the real history is everything but the last.
    private static func oddsAnswer(_ q: String, plan: MoneyPlan, months: [MonthRecord]) -> ChatAnswer? {
        let markers = ["odds", "chance", "chances", "likely", "likelihood", "probability",
                       "how often", "percent chance", "% chance", "what are the odds",
                       "how safe am i", "risk of debt", "risk of going"]
        guard has(q, markers) else { return nil }

        let history = months.isEmpty ? [] : Array(months.dropLast())
        guard let r = MonteCarloEngine.simulate(plan: plan, history: history, runs: 500, seed: 42) else {
            return needNumbers()
        }
        let p6 = Int((r.probNegativeWithin6mo * 100).rounded())
        let p12 = Int((r.probNegativeWithin12mo * 100).rounded())
        let basis = r.mode == .personalHistory ? "your own recent months" : "typical month-to-month ups and downs"

        var text = "I ran your numbers across \(r.runs) possible versions of the year — based on \(basis). "
        if p6 == 0 && p12 == 0 {
            text += "Almost none dipped into the red — you're on steady ground. "
        } else {
            text += "About **\(p6)%** dipped into the red within 6 months, and **\(p12)%** within 12. "
        }
        text += "By this time next year you'd most likely land around \(money(r.p50_12mo)), somewhere between \(money(r.p10_12mo)) and \(money(r.p90_12mo))."
        return ChatAnswer(
            text: text,
            provenance: "Simulation of your numbers, on this device",
            followUps: ["What's my fastest fix?", "Where is my month heading?"]
        )
    }

    // MARK: - Situation (the synthesized verdict / early-warning)

    /// "Am I going into debt", "am I in trouble", "where's this heading",
    /// "is this getting worse" — answered by `SituationEngine`, which weighs
    /// being over budget, how heavy debt already is, and where the trend points.
    private static func situationAnswer(_ q: String, plan: MoneyPlan, months: [MonthRecord]) -> ChatAnswer? {
        let markers = ["heading", "headed", "trajectory", "getting worse", "getting better",
                       "where am i going", "where is this going", "where this is going",
                       "where is this heading", "am i heading", "toward debt", "towards debt",
                       "into debt", "in debt", "debt trouble", "on track", "coming months",
                       "am i improving", "will i be short", "will i run out", "my trend",
                       "am i in trouble", "how bad", "where do i stand", "my situation",
                       "am i drifting", "how deep"]
        guard has(q, markers) else { return nil }

        guard let read = SituationEngine.assess(plan: plan, months: months) else {
            return needNumbers()
        }
        return ChatAnswer(
            text: "\(read.headline)\n\n\(read.detail)",
            provenance: "Your numbers, on this device",
            followUps: ["What's my fastest fix?", "How do all my costs compare?"]
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
            if share > MoneyPlan.safeLineShare {
                text = "You're okay this month. Essentials are \(money(essentials)) — \(sharePct) of your \(money(income)) income, a little past the safe line, but the \(money(left)) left over is a comfortable cushion. Your biggest cost is **\(biggest.label.lowercased())** at \(money(biggest.amount))."
            } else {
                text = "You're okay this month. Essentials are \(money(essentials)) — \(sharePct) of your \(money(income)) income, under the safe line — leaving you \(money(left)). Your biggest cost is **\(biggest.label.lowercased())** at \(money(biggest.amount))."
            }
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

    // MARK: - Money questions (cushion, savings, debt, annual)

    /// "How's my cushion / emergency fund / how long to save one" — the 3–6
    /// month essentials guideline, and how long the current surplus would take
    /// to build it. Educational heuristic, clearly labeled.
    private static func cushionAnswer(_ q: String, plan: MoneyPlan) -> ChatAnswer? {
        let markers = ["cushion", "emergency fund", "rainy day", "safety net",
                       "buffer", "runway", "months of essentials",
                       "how long could i last", "savings target", "save up"]
        guard has(q, markers) else { return nil }
        guard let left = plan.moneyLeft else { return needNumbers() }
        let essentials = plan.essentialsTotal
        let target3 = essentials * 3, target6 = essentials * 6

        var text = "A common rule of thumb is to keep **3 to 6 months of essentials** set aside for emergencies. For you that's about **\(money(target3))** (3 months) to **\(money(target6))** (6 months)."
        if left > 0 {
            let months = max(1, Int((target3 / left).rounded()))
            text += "\n\nAt the **\(money(left))** you keep each month, you'd build the 3-month cushion in roughly **\(months) month\(months == 1 ? "" : "s")** — if you set that money aside."
        } else if left == 0 {
            text += "\n\nRight now nothing's left over to set aside — freeing up a little each month is the place to start."
        } else {
            text += "\n\nRight now the month doesn't fully cover itself, so there's nothing to set aside yet — closing that gap comes first."
        }
        text += "\n\nThis is a general guideline, not advice; your own right number depends on your situation."
        return ChatAnswer(text: text, provenance: "Your numbers · 3–6 month guideline",
                          followUps: ["What's my fastest fix?", "How much do I keep each month?"])
    }

    /// "How much do I keep / save each month" — the surplus, as dollars, a share
    /// of income, and an annual pace.
    private static func savingsRateAnswer(_ q: String, plan: MoneyPlan) -> ChatAnswer? {
        let markers = ["how much do i keep", "how much am i saving", "savings rate",
                       "how much do i save", "left over each", "keep each month",
                       "put away", "am i saving", "how much can i save",
                       "how much is left over", "how much left over"]
        guard has(q, markers) else { return nil }
        guard let income = plan.monthlyIncome, income > 0, let left = plan.moneyLeft else { return needNumbers() }
        if left > 0 {
            let text = "After essentials you keep **\(money(left))** a month — that's **\(percent(left / income))** of your income. If this month repeated, that's about **\(money(left * 12))** over a year. Setting even part of it aside builds a cushion."
            return ChatAnswer(text: text, provenance: "Your numbers",
                              followUps: ["How's my cushion?", "What's my fastest fix?"])
        }
        let text = left == 0
            ? "Your essentials use up just about all your income this month, so there's nothing left over to save. Freeing up a little is the place to start."
            : "There's nothing to save this month — you're **\(money(-left)) short** after essentials. Closing that gap comes first; I can show you the biggest lever."
        return ChatAnswer(text: text, provenance: "Your numbers",
                          followUps: ["What's my fastest fix?", "Why is it tight?"])
    }

    /// "How much of my income goes to debt" — the debt-payment share, with the
    /// 20% / 36% rules of thumb.
    private static func debtBurdenAnswer(_ q: String, plan: MoneyPlan) -> ChatAnswer? {
        let markers = ["how much goes to debt", "debt to income", "debt burden",
                       "how much on debt", "spending on debt", "debt payments take",
                       "how much is debt", "how much for debt", "debt take",
                       "share of income goes to debt", "much of my income"]
        guard has(q, markers) else { return nil }
        guard let income = plan.monthlyIncome, income > 0 else { return needNumbers() }
        let debt = plan.debtPayments ?? 0
        guard debt > 0 else {
            return ChatAnswer(
                text: "You haven't entered any debt payments, so none of your income is going to debt right now. If that changes, add it on the home screen and I'll factor it in.",
                provenance: "Your numbers",
                followUps: ["How much do I keep each month?", "What's my fastest fix?"])
        }
        let share = debt / income
        var text = "Your debt payments are **\(money(debt))** a month — about **\(percent(share))** of your income."
        if share <= CostComparisons.debtHealthyShare {
            text += " That's comfortably under the 20% often considered manageable for non-housing debt."
        } else if share <= CostComparisons.debtHighShare {
            text += " That's past the usual 20% comfort line but under the 36% considered heavy — worth keeping an eye on."
        } else {
            text += " That's past the 36% usually considered heavy. Bringing it down is the surest way to free up room — and if it's a lot to carry, dialling **211** reaches free local help."
        }
        text += "\n\n(These percentages are common rules of thumb, not hard rules.)"
        return ChatAnswer(text: text, provenance: "Your numbers · 20% / 36% guideline",
                          followUps: ["What's my fastest fix?", "Am I heading toward debt?"])
    }

    /// "Over a year / annually" — the current month's surplus or deficit,
    /// projected across twelve months, clearly flagged as a rough pace.
    private static func annualAnswer(_ q: String, plan: MoneyPlan) -> ChatAnswer? {
        let markers = ["over a year", "in a year", "per year", "each year", "yearly",
                       "annual", "12 months", "twelve months", "whole year", "a full year"]
        guard has(q, markers) else { return nil }
        guard let left = plan.moneyLeft else { return needNumbers() }
        let yearly = left * 12
        let text: String
        if left > 0 {
            text = "If this month repeated all year, you'd keep about **\(money(yearly))** over 12 months (\(money(left)) a month). Real life varies, so treat it as a rough pace, not a promise."
        } else if left == 0 {
            text = "At this month's pace you'd roughly break even over the year — essentials use up just about all your income. Freeing up a little would start building room."
        } else {
            text = "If this month repeated all year, you'd be about **\(money(-yearly))** short over 12 months (\(money(-left)) a month). Closing the monthly gap is what changes that."
        }
        return ChatAnswer(text: text, provenance: "Your numbers, projected",
                          followUps: ["Where does my money go?", "What's my fastest fix?"])
    }

    private static func safeLineExplanation(_ plan: MoneyPlan) -> ChatAnswer {
        let linePct = percent(MoneyPlan.safeLineShare)
        var text = "The safe line is a simple guide: try to keep your essentials — rent, food, energy, debt payments — under \(linePct) of what comes in. Below it, you've usually got room for everything else and a bit to save. Past it, there's less room to spare — though what really matters is how many dollars you keep."
        if let income = plan.monthlyIncome, let safe = plan.safeLineAmount, income > 0 {
            text += "\n\nFor your \(money(income)) income, that line sits at about \(money(safe)) of essentials."
            if let share = plan.essentialsShare {
                if share <= MoneyPlan.safeLineShare {
                    text += " You're under it — nice."
                } else if plan.status == .okay, let left = plan.moneyLeft {
                    text += " You're a little over it, at \(percent(share)), but the \(money(left)) you keep each month is a comfortable cushion."
                } else {
                    text += " Right now you're a little over it, at \(percent(share))."
                }
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
        case .homeUpkeep: return plan.homeUpkeep
        case .food: return plan.food
        case .energy: return plan.energy
        case .water: return plan.water
        case .transportation: return plan.transportation
        case .personal: return plan.personal
        case .debt: return plan.debtPayments
        }
    }

    private static func set(_ kind: EssentialKind, to newValue: Double, in plan: inout MoneyPlan) {
        switch kind {
        case .housing: plan.housing = newValue
        case .homeUpkeep: plan.homeUpkeep = newValue
        case .food: plan.food = newValue
        case .energy: plan.energy = newValue
        case .water: plan.water = newValue
        case .transportation: plan.transportation = newValue
        case .personal: plan.personal = newValue
        case .debt: plan.debtPayments = newValue
        }
    }

    private static func category(in q: String) -> EssentialKind? {
        if has(q, ["rent", "mortgage", "housing", "apartment", "landlord"]) { return .housing }
        if has(q, ["property tax", "home insurance", "homeowner", "upkeep", "maintenance", "landscap", "pest", "repairs"]) { return .homeUpkeep }
        if has(q, ["food", "grocer", "groceries", "eating", "meals"]) { return .food }
        // Utilities is one combined cost now — electricity, gas, water, trash.
        if has(q, ["utilit", "energy", "electric", "heating", "power bill", "gas bill", "water", "sewer", "trash", "garbage"]) { return .energy }
        if has(q, ["car", "gas", "fuel", "transport", "vehicle", "commut", "auto", "rideshare", "transit"]) { return .transportation }
        if has(q, ["clothes", "clothing", "entertainment", "hobby", "hobbies", "subscription", "personal", "fun"]) { return .personal }
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
