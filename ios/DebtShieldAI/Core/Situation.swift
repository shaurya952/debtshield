import Foundation

/// The synthesized verdict — the single most important read in the app.
///
/// A month's `MoneyStatus` is a snapshot ("it's tight"). This is the *story*: it
/// weighs whether you're over budget, how heavy your debt already is, and where
/// the trend is heading, then says plainly where you stand on the road to (or
/// out of) debt. It escalates:
///
/// good → watch → tight → heading into debt → going into debt → deep in debt
///
/// Everything is computed on the device from your own numbers. At the serious
/// end it points toward free human help, the way the rest of the app does.
enum Situation: String, Equatable, Sendable, CaseIterable {
    case good
    case watch
    case tight
    case headingToDebt
    case goingIntoDebt
    case deepInDebt

    /// 0…5 — used to decide how much visual weight the card carries.
    var severity: Int { Self.allCases.firstIndex(of: self) ?? 0 }

    var symbol: String {
        switch self {
        case .good: return "checkmark.seal.fill"
        case .watch: return "eye.fill"
        case .tight: return "equal.circle.fill"
        case .headingToDebt: return "exclamationmark.triangle.fill"
        case .goingIntoDebt: return "arrow.down.right.circle.fill"
        case .deepInDebt: return "exclamationmark.octagon.fill"
        }
    }
}

struct SituationRead: Equatable, Sendable {
    let situation: Situation
    let headline: String
    let detail: String
}

enum SituationEngine {

    /// Debt payments above this share of income are "heavy" (the classic 36%
    /// total-debt ceiling; here it's non-housing debt, so it's a strong signal).
    static let heavyDebtShare = 0.36
    /// Above this, debt is worth watching.
    static let highDebtShare = 0.20

    /// Reads the whole situation. `months` is oldest→newest and includes the
    /// current month.
    static func assess(plan: MoneyPlan, months: [MonthRecord]) -> SituationRead? {
        guard plan.isComplete, let income = plan.monthlyIncome, income > 0,
              let left = plan.moneyLeft, let status = plan.status else { return nil }

        let debtShare = (plan.debtPayments ?? 0) / income
        let debtPct = Int((debtShare * 100).rounded())
        let heavyDebt = debtShare >= heavyDebtShare
        let highDebt = debtShare >= highDebtShare
        let over = left < 0

        let recent = Array(months.suffix(6))
        let shortMonths = recent.filter { ($0.moneyLeft ?? 0) < 0 }.count
        let values = months.compactMap { $0.moneyLeft }
        let trajectory = months.last.flatMap {
            TrajectoryEngine.read(moneyLeft: values, currentMonthKey: $0.monthKey)
        }
        let slipping = trajectory?.direction == .slipping
        let gapGrowing = trajectory?.direction == .underwater
            && (trajectory?.perMonth ?? 0) < -TrajectoryEngine.steadyBand

        let situation: Situation
        let headline: String
        var detail: String

        if over {
            let gap = money(-left)
            if heavyDebt || shortMonths >= 3 || gapGrowing {
                situation = .deepInDebt
                headline = "You're carrying heavy debt"
                let reason: String
                if heavyDebt { reason = debtPhrase(debtShare, debtPct) }
                else if gapGrowing { reason = "the gap keeps widening" }
                else { reason = "you've been short \(shortMonths) of the last \(recent.count) months" }
                detail = "You're spending \(gap) more than you bring in, and \(reason). That's a lot to carry alone — and there's free, judgment-free help. Dialling **211** reaches local assistance, and HUD-approved counsellors give free money and housing guidance."
            } else {
                situation = .goingIntoDebt
                headline = "You're going into debt this month"
                detail = "You're spending about \(gap) more than comes in. That gap has to come from savings or borrowing — which is how debt starts. Let's find the fastest thing to change. If you need it, dialling **211** connects you to free local support."
            }
        } else if slipping {
            situation = .headingToDebt
            headline = "You may be heading into debt"
            let when = trajectory?.shortMonthKey.map { MonthRecord.label(for: $0) }
            let clause = when.map { " — at this pace you'd be short around **\($0)**" } ?? ""
            detail = "You're still covering the month, but your room has been shrinking\(clause). Now, while you're still ahead, is the easy time to change course."
        } else if heavyDebt {
            situation = .headingToDebt
            headline = "Your debt is getting heavy"
            detail = "You're covering the month, but \(debtPhrase(debtShare, debtPct)) — past the 36% that's usually comfortable. Bringing it down is the surest way to stay clear of trouble."
        } else if status == .tight {
            situation = .tight
            headline = "It's tight this month"
            detail = "Your basics take a big slice of your income. You're covered, but there's little room to spare — worth watching so it doesn't tip over."
        } else if highDebt {
            situation = .watch
            headline = "Worth keeping an eye on"
            detail = "You're comfortably covered this month, but \(debtPhrase(debtShare, debtPct)). Manageable — trimming it a little keeps it from creeping up."
        } else {
            situation = .good
            headline = "You're in good shape"
            detail = "Your basics are comfortably covered, and nothing's trending the wrong way. A little of what's left over could start becoming a cushion."
        }

        // Before there's a trend, promise the early-warning.
        if trajectory == nil, situation.severity <= Situation.tight.severity {
            detail += " Check back each month — I'll flag any drift toward debt early, right here on your phone."
        }

        return SituationRead(situation: situation, headline: headline, detail: detail)
    }

    /// Describes the debt load without ever printing an absurd percentage —
    /// someone can enter debt payments larger than their income.
    private static func debtPhrase(_ share: Double, _ pct: Int) -> String {
        if share >= 1.0 { return "your debt payments are more than your whole income" }
        return "debt takes about \(pct)% of your income"
    }

    private static func money(_ value: Double) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }
}
