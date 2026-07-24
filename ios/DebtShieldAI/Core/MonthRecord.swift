import Foundation

/// One finished month's money picture, kept so the app can show how things are
/// trending — the difference between a snapshot and a story.
///
/// `monthKey` is a sortable "yyyy-MM" string. The plan is stored whole, so any
/// figure (money left, status, essentials) can be re-derived without freezing a
/// stale copy of the maths.
struct MonthRecord: Codable, Equatable, Identifiable, Sendable {
    let monthKey: String
    let plan: MoneyPlan

    var id: String { monthKey }

    var moneyLeft: Double? { plan.moneyLeft }
    var status: MoneyStatus? { plan.status }

    /// "Jul 2026" — unambiguous and plain.
    var label: String { MonthRecord.label(for: monthKey) }
    /// "Jul" — for tight spaces like a bar-chart axis.
    var shortLabel: String { MonthRecord.label(for: monthKey, includeYear: false) }

    // MARK: - Keys and labels

    /// The "yyyy-MM" key for a date, in the current calendar.
    static func key(for date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", c.year ?? 0, c.month ?? 0)
    }

    /// A "yyyy-MM" key `n` months after the given key.
    static func addMonths(_ n: Int, to key: String, calendar: Calendar = .current) -> String {
        let parts = key.split(separator: "-")
        guard parts.count == 2, let year = Int(parts[0]), let month = Int(parts[1]) else { return key }
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        guard let base = calendar.date(from: comps),
              let future = calendar.date(byAdding: .month, value: n, to: base) else { return key }
        return MonthRecord.key(for: future, calendar: calendar)
    }

    /// Turns a "yyyy-MM" key into a readable month label.
    static func label(for key: String, includeYear: Bool = true) -> String {
        let parts = key.split(separator: "-")
        guard parts.count == 2, let month = Int(parts[1]), (1...12).contains(month) else { return key }
        let symbols = DateFormatter().shortMonthSymbols ?? []
        let name = (month - 1) < symbols.count ? symbols[month - 1] : "\(month)"
        return includeYear ? "\(name) \(parts[0])" : name
    }
}
