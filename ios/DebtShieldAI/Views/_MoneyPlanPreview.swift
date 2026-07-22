#if DEBUG
import SwiftUI

/// TEMPORARY Step-1 verification harness. Not shipped, not linked from anywhere.
///
/// It exists only so the `MoneyPlan` math can be eyeballed in Xcode's canvas
/// before any real UI is built. Open this file and use the canvas preview.
/// **Delete this file once the real Safe Line screen (Step 3+) exists** — it is
/// throwaway scaffolding, deliberately prefixed with `_` so it sorts to the top
/// and is easy to find and remove.
private struct MoneyPlanDump: View {
    let title: String
    let plan: MoneyPlan

    private func money(_ value: Double?) -> String {
        guard let value else { return "—" }
        return value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }

    private func percent(_ share: Double?) -> String {
        guard let share else { return "—" }
        return (share * 100).formatted(.number.precision(.fractionLength(0))) + "%"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            Group {
                Text("income:        \(money(plan.monthlyIncome))")
                Text("essentials:    \(money(plan.essentialsTotal))")
                Text("share:         \(percent(plan.essentialsShare))")
                Text("safe line:     \(money(plan.safeLineAmount)) (\(percent(MoneyPlan.safeLineShare)))")
                Text("money left:    \(money(plan.moneyLeft))")
                Text("status:        \(plan.status?.rawValue ?? "nil") — \(plan.status?.headline ?? "not enough entered")")
                Text("segments:      \(plan.segments.map { "\($0.label) \(money($0.amount))" }.joined(separator: ", "))")
            }
            .font(.system(.footnote, design: .monospaced))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview("MoneyPlan math") {
    ScrollView {
        VStack(spacing: 12) {
            MoneyPlanDump(title: "OKAY  (expect okay, $2,240 left, 44%)", plan: .sampleOkay)
            MoneyPlanDump(title: "TIGHT (expect tight, $1,050 left, 65%)", plan: .sampleTight)
            MoneyPlanDump(title: "OVER  (expect over, −$250 left, 110%)", plan: .sampleOver)
            MoneyPlanDump(title: "EMPTY (expect nil status)", plan: .empty)
            MoneyPlanDump(title: "INCOME ONLY (expect nil status)", plan: MoneyPlan(monthlyIncome: 3_000))
        }
        .padding()
    }
    .background(Color(uiColor: .systemGroupedBackground))
}
#endif
