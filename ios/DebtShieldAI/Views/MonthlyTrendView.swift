import SwiftUI

/// A small bar per month, showing money left over time — the shape of the
/// trend, not a precise chart. Each bar is coloured by that month's situation
/// (green / amber / red) and carries a full spoken label for VoiceOver.
struct MonthlyTrendView: View {
    /// Oldest to newest; the last one is the current month.
    let months: [MonthRecord]
    var barAreaHeight: CGFloat = 84

    private var maxLeft: Double {
        max(months.compactMap { $0.moneyLeft }.map { Swift.max($0, 0) }.max() ?? 1, 1)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: Theme.Spacing.tight) {
            ForEach(months) { month in
                column(for: month, isCurrent: month.id == months.last?.id)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func column(for month: MonthRecord, isCurrent: Bool) -> some View {
        let left = month.moneyLeft ?? 0
        let status = month.status ?? .okay
        // Positive months scale by height; an over-budget month shows a short
        // red stub so it still reads as "there, but underwater".
        let fraction = left > 0 ? left / maxLeft : 0
        let height = max(6, barAreaHeight * fraction)

        return VStack(spacing: 6) {
            Text(shortMoney(left))
                .font(.caption2.weight(.semibold).monospacedDigit())
                .foregroundStyle(isCurrent ? Theme.statusColor(status) : Theme.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            VStack {
                Spacer(minLength: 0)
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Theme.statusColor(status).opacity(isCurrent ? 1 : 0.55))
                    .frame(height: height)
            }
            .frame(height: barAreaHeight, alignment: .bottom)

            Text(month.shortLabel)
                .font(.caption2)
                .foregroundStyle(isCurrent ? .primary : Theme.secondaryText)
                .fontWeight(isCurrent ? .semibold : .regular)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(month.label): \(spoken(left))\(isCurrent ? ", this month" : "")")
    }

    private func shortMoney(_ value: Double) -> String {
        let sign = value < 0 ? "−" : ""
        return sign + "$" + abs(value).formatted(.number.precision(.fractionLength(0)))
    }

    private func spoken(_ value: Double) -> String {
        let amount = abs(value).formatted(.currency(code: "USD").precision(.fractionLength(0)))
        return value >= 0 ? "\(amount) left" : "\(amount) short"
    }
}

#if DEBUG
#Preview {
    MonthlyTrendView(months: [
        MonthRecord(monthKey: "2026-04", plan: MoneyPlan(monthlyIncome: 2800, housing: 1500, food: 400, energy: 220, debtPayments: 300)),
        MonthRecord(monthKey: "2026-05", plan: MoneyPlan(monthlyIncome: 3000, housing: 1500, food: 420, energy: 200, debtPayments: 300)),
        MonthRecord(monthKey: "2026-06", plan: MoneyPlan(monthlyIncome: 3000, housing: 1500, food: 350, energy: 180, debtPayments: 150)),
        MonthRecord(monthKey: "2026-07", plan: .sampleOkay)
    ])
    .padding()
}
#endif
