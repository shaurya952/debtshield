import SwiftUI

/// The Safe Line bar — the single most important view in the app.
///
/// It reads as one sentence: *this is your income; this much is spoken for by
/// essentials; this much is left; and here is the line those essentials
/// shouldn't cross.*
///
/// ## Geometry
///
/// Everything is scaled against `denominator = max(income, essentials)`. In the
/// normal case that's income, so the track represents one month's pay and the
/// essentials fill part of it. When essentials exceed income the denominator
/// becomes essentials, so the segments fill the whole track and the stretch
/// *past* where income ends is drawn as a red overflow zone — the bar visibly
/// spilling over.
///
/// Colour is never the only signal: every segment is labelled in the legend
/// beneath, the safe line carries the words "safe line", and the whole bar has
/// a single spoken accessibility summary.
struct SafeLineBar: View {
    let plan: MoneyPlan
    var barHeight: CGFloat = 64
    /// The "safe line" caption under the bar. Hidden on the compact home hero,
    /// where space is tight and the insight line already names the safe line.
    var showsCaption: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var income: Double { max(plan.monthlyIncome ?? 0, 0) }
    private var essentials: Double { plan.essentialsTotal }
    private var isOver: Bool { essentials > income && income > 0 }

    /// Never zero — guards the width maths against an empty plan.
    private var denominator: Double { max(income, essentials, 1) }

    /// Each segment paired with the running dollar total before it, so the view
    /// can place it without re-summing on every frame.
    private var placed: [(segment: EssentialSegment, start: Double)] {
        var running = 0.0
        return plan.segments.map { segment in
            defer { running += segment.amount }
            return (segment, running)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.tight) {
            GeometryReader { geo in
                let width = geo.size.width
                let scale = width / denominator

                ZStack(alignment: .leading) {
                    // Track.
                    Capsule().fill(Color(uiColor: .tertiarySystemFill))

                    // Money left — the gap after essentials, up to income. Soft
                    // green: this is money the person keeps.
                    if let left = plan.moneyLeft, left > 0 {
                        Rectangle()
                            .fill(Theme.statusColor(.okay).opacity(0.20))
                            .frame(width: max(0, left * scale))
                            .offset(x: essentials * scale)
                    }

                    // Essentials, left to right.
                    ForEach(placed, id: \.segment.id) { item in
                        let segWidth = max(0, item.segment.amount * scale)
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [
                                    Theme.essentialColor(item.segment.kind),
                                    Theme.essentialColor(item.segment.kind).opacity(0.82)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ))
                            .frame(width: segWidth)
                            .overlay(alignment: .leading) {
                                // Label inside only when it comfortably fits;
                                // the legend below covers the narrow ones.
                                if segWidth > 78 {
                                    Text(item.segment.label)
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                        .padding(.leading, Theme.Spacing.tight)
                                }
                            }
                            .offset(x: item.start * scale)
                    }

                    // Overflow: the stretch of essentials beyond income.
                    if isOver {
                        Rectangle()
                            .fill(Theme.statusColor(.over).opacity(0.30))
                            .frame(width: (essentials - income) * scale)
                            .offset(x: income * scale)
                            .allowsHitTesting(false)
                    }

                    // Where income runs out — only worth marking when it's not
                    // the end of the bar, i.e. when essentials overflow past it.
                    if isOver {
                        marker(x: income * scale, height: geo.size.height, dashed: false)
                    }

                    // The safe line itself.
                    if let safe = plan.safeLineAmount {
                        marker(x: safe * scale, height: geo.size.height, dashed: true)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: barHeight / 2, style: .continuous))
                .animation(reduceMotion ? nil : .easeOut(duration: 0.4), value: plan)
            }
            .frame(height: barHeight)

            // A legend under the bar so every segment is named, not just the wide
            // ones that fit a label inside — colour is never the only signal.
            if !plan.segments.isEmpty {
                legend
            }

            // The "safe line" caption sits under the bar so it never crowds the
            // segments.
            if showsCaption {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                        .font(.caption2.weight(.bold))
                    Text("safe line — keep the basics under \(Int((MoneyPlan.safeLineShare * 100).rounded()))% of your income")
                        .font(Theme.Typography.caption)
                }
                .foregroundStyle(Theme.secondaryText)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    /// Wrapping legend of coloured dot + label for every essential in the bar.
    private var legend: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 88), spacing: 8, alignment: .leading)],
            alignment: .leading, spacing: 4
        ) {
            ForEach(plan.segments) { seg in
                HStack(spacing: 5) {
                    Circle().fill(Theme.essentialColor(seg.kind)).frame(width: 8, height: 8)
                    Text(seg.label)
                        .font(.caption2).foregroundStyle(Theme.secondaryText).lineLimit(1)
                }
            }
            if let left = plan.moneyLeft, left > 0 {
                HStack(spacing: 5) {
                    Circle().fill(Theme.statusColor(.okay).opacity(0.35)).frame(width: 8, height: 8)
                    Text("Left over").font(.caption2).foregroundStyle(Theme.secondaryText).lineLimit(1)
                }
            }
        }
        .accessibilityHidden(true)
    }

    /// A thin vertical rule across the bar. Dashed for the safe line (a
    /// guideline), solid for the income cut-off (a hard edge).
    private func marker(x: CGFloat, height: CGFloat, dashed: Bool) -> some View {
        VerticalRule(dashed: dashed)
            .stroke(
                Color.primary.opacity(dashed ? 0.6 : 0.85),
                style: StrokeStyle(lineWidth: 2, dash: dashed ? [4, 3] : [])
            )
            .frame(width: 2, height: height)
            .offset(x: x - 1)
    }

    private func money(_ value: Double) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }

    private var accessibilitySummary: String {
        guard plan.isComplete, let left = plan.moneyLeft else {
            return "Safe line bar. Not enough entered yet."
        }
        let segmentsText = plan.segments
            .map { "\($0.label) \(money($0.amount))" }
            .joined(separator: ", ")
        let leftText = left >= 0
            ? "\(money(left)) left this month."
            : "over by \(money(abs(left))) this month."
        return "Income \(money(income)). Essentials: \(segmentsText). \(leftText) \(plan.status?.headline ?? "")."
    }
}

/// A top-to-bottom line, drawn as a `Shape` so it can take a dashed stroke.
private struct VerticalRule: Shape {
    var dashed: Bool
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}

#if DEBUG
#Preview("Safe Line bar — states") {
    VStack(alignment: .leading, spacing: 28) {
        VStack(alignment: .leading) {
            Text("OKAY (44%)").font(.caption).foregroundStyle(.secondary)
            SafeLineBar(plan: .sampleOkay)
        }
        VStack(alignment: .leading) {
            Text("TIGHT (65%)").font(.caption).foregroundStyle(.secondary)
            SafeLineBar(plan: .sampleTight)
        }
        VStack(alignment: .leading) {
            Text("OVER (110%)").font(.caption).foregroundStyle(.secondary)
            SafeLineBar(plan: .sampleOver)
        }
        VStack(alignment: .leading) {
            Text("EXTREME OVER (180%)").font(.caption).foregroundStyle(.secondary)
            SafeLineBar(plan: MoneyPlan(monthlyIncome: 2_000, housing: 2_200,
                                        food: 600, energy: 400, debtPayments: 400))
        }
    }
    .padding()
}
#endif
