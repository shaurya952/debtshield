import Foundation

/// A plain-language "what changed since last month" read.
///
/// This is **actual history** — the current month compared to the most recent
/// finished month — kept deliberately separate from the year-ahead simulation,
/// which is a projection. Pure and synchronous, so it's headlessly testable.
struct MonthChange: Equatable, Sendable {
    /// This month's money-left minus last month's. Positive means more room.
    let moneyLeftDelta: Double
    let lastMonthLabel: String
    /// One plain line about the change in room.
    let headline: String
    /// The single figure that moved the most, if any (e.g. "Mostly because food
    /// went up $70."). `nil` when nothing meaningfully changed.
    let driver: String?

    var isImprovement: Bool { moneyLeftDelta >= 0 }
    var isFlat: Bool { abs(moneyLeftDelta) < 1 }
}

enum MonthChangeEngine {

    /// Compares the current plan to a finished month. Returns `nil` if either
    /// month lacks a usable money-left figure.
    static func compare(current: MoneyPlan, last: MonthRecord) -> MonthChange? {
        guard let now = current.moneyLeft, let then = last.moneyLeft else { return nil }
        let delta = now - then
        let label = last.label

        let headline: String
        if abs(delta) < 1 {
            headline = "About the same room as \(label)."
        } else {
            headline = "\(money(abs(delta))) \(delta > 0 ? "more" : "less") room than \(label)."
        }

        return MonthChange(
            moneyLeftDelta: delta,
            lastMonthLabel: label,
            headline: headline,
            driver: biggestDriver(current: current, last: last.plan)
        )
    }

    /// The single figure that moved the most between the two months. Neutral
    /// wording — it never calls a change good or bad.
    private static func biggestDriver(current: MoneyPlan, last: MoneyPlan) -> String? {
        var moves: [(label: String, delta: Double)] = []
        func add(_ label: String, _ a: Double?, _ b: Double?) {
            if let a, let b, abs(a - b) >= 1 { moves.append((label, a - b)) }
        }
        add("income", current.monthlyIncome, last.monthlyIncome)
        add("rent or mortgage", current.housing, last.housing)
        add("food", current.food, last.food)
        add("energy", current.energy, last.energy)
        add("debt payments", current.debtPayments, last.debtPayments)

        guard let top = moves.max(by: { abs($0.delta) < abs($1.delta) }) else { return nil }
        let direction = top.delta > 0 ? "went up" : "went down"
        return "Mostly because \(top.label) \(direction) \(money(abs(top.delta)))."
    }

    private static func money(_ value: Double) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }
}
