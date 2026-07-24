import SwiftUI

/// The home screen — the personal heart of the app.
///
/// It answers one question in dollars — *how does this month stand?* — with the
/// Safe Line bar, a single headline figure, a plain-language read of where you
/// are, and a clear way into the comparison. No score, no grade, no jargon.
///
/// It depends only on `MoneyPlanStore`, never on the county data. A person's
/// budget must never wait on — or fail with — anything else.
struct SafeLineView: View {
    let store: MoneyPlanStore
    /// Jumps to the Compare tab.
    var onCompare: () -> Void

    @State private var isEditing = false

    /// The big money figure — larger than any Theme style, scales with type.
    @ScaledMetric(relativeTo: .largeTitle) private var heroSize: CGFloat = 46

    private var plan: MoneyPlan { store.plan }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                if plan.isComplete {
                    resultCard
                    nextStepCard
                    askLink
                    compareCard
                    monthsCard
                    breakdownCard
                    editButton
                } else {
                    emptyState
                }
            }
            .padding(Theme.Spacing.comfortable)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.screenBackground)
        .navigationTitle("Your month")
        .sheet(isPresented: $isEditing) {
            MyNumbersView(store: store)
        }
    }

    // MARK: - Result (hero)

    @ViewBuilder
    private var resultCard: some View {
        let status = plan.status ?? .okay
        VStack(alignment: .leading, spacing: Theme.Spacing.comfortable) {
            StatusPill(status: status)

            if let left = plan.moneyLeft {
                VStack(alignment: .leading, spacing: 2) {
                    Text(headlineAmount(left))
                        .font(.system(size: heroSize, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                    Text(left >= 0 ? "left this month" : "short this month")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(spokenMoneyLeft(left))
            }

            SafeLineBar(plan: plan)
                .padding(.top, Theme.Spacing.tight)

            Text(insight)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            if let trend = trendLine {
                Divider()
                Label {
                    Text(trend.text)
                        .font(Theme.Typography.subheadline)
                } icon: {
                    Image(systemName: trend.up ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(trend.up ? Theme.statusColor(.okay) : Theme.secondaryText)
                .accessibilityElement(children: .combine)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.comfortable)
        .background {
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .fill(Theme.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                        .fill(Theme.statusWash(status))
                }
                .shadow(color: Theme.heroShadow, radius: 14, x: 0, y: 8)
        }
    }

    /// A plain, kind read of the month — concrete numbers, no jargon.
    private var insight: String {
        guard let share = plan.essentialsShare, let status = plan.status else { return "" }
        let pct = Int((share * 100).rounded())
        switch status {
        case .okay:
            return "You're spending \(pct)% of what you earn on the basics — under your safe line. You've got room."
        case .tight:
            let over = (plan.safeLineAmount.map { plan.essentialsTotal - $0 }) ?? 0
            return "You're spending \(pct)% on the basics — a little over the safe line. About \(money(max(0, over))) less would put you back under."
        case .over:
            let short = plan.moneyLeft.map { -$0 } ?? 0
            return "The basics cost more than you bring in — about \(money(short)) more. Ask below for the fastest way to free up room."
        }
    }

    private func headlineAmount(_ left: Double) -> String {
        let magnitude = left.magnitude.formatted(.currency(code: "USD").precision(.fractionLength(0)))
        return left >= 0 ? magnitude : "−\(magnitude)"
    }

    /// A spoken version of the headline, so VoiceOver says "250 dollars short
    /// this month" rather than reading a minus glyph.
    private func spokenMoneyLeft(_ left: Double) -> String {
        let amount = left.magnitude.formatted(.currency(code: "USD").precision(.fractionLength(0)))
        return left >= 0 ? "\(amount) left this month" : "\(amount) short this month"
    }

    // MARK: - Trend vs last month

    private var trendLine: (text: String, up: Bool)? {
        guard let now = plan.moneyLeft,
              let last = store.lastMonth, let then = last.moneyLeft else { return nil }
        let diff = now - then
        if abs(diff) < 1 {
            return ("About the same as \(last.label)", true)
        }
        let amount = money(abs(diff))
        return ("\(amount) \(diff > 0 ? "more" : "less") than \(last.label)", diff > 0)
    }

    // MARK: - Your months

    /// Past months (oldest first) plus this month, capped to the last six.
    private var recentMonths: [MonthRecord] {
        var months = store.history.reversed().map { $0 }
        if plan.isComplete, !store.month.isEmpty {
            months.append(MonthRecord(monthKey: store.month, plan: plan))
        }
        return Array(months.suffix(6))
    }

    @ViewBuilder
    private var monthsCard: some View {
        if !store.history.isEmpty, recentMonths.count >= 2 {
            Card {
                SectionHeader(
                    title: "Your months",
                    subtitle: "How much you had left, month to month"
                )
                MonthlyTrendView(months: recentMonths)
                    .padding(.top, Theme.Spacing.tight)
            }
        }
    }

    // MARK: - Where to start

    /// A gentle, immediate nudge — only when money's tight or over. Names the
    /// biggest lever in dollars, and points at the easiest one to move.
    @ViewBuilder
    private var nextStepCard: some View {
        if let status = plan.status, status != .okay, let biggest = plan.biggestEssential {
            Card {
                Label("Where to start", systemImage: "arrow.up.forward.circle.fill")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.brand)
                Text(nextStepText(biggest: biggest))
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func nextStepText(biggest: EssentialSegment) -> String {
        var text = "Your biggest cost is \(biggest.label.lowercased()) at \(money(biggest.amount)). Trimming even a little there frees up the most — every $50 less is $50 back this month."
        if biggest.kind == .housing, let movable = plan.biggestMovableEssential {
            text += " Rent's the hardest to change fast, so \(movable.label.lowercased()) (\(money(movable.amount))) is often an easier place to start."
        }
        return text
    }

    // MARK: - Compare

    private var compareCard: some View {
        Button {
            onCompare()
        } label: {
            ActionRowLabel(
                systemImage: "chart.bar.xaxis",
                title: "See how you compare",
                subtitle: "Your spending vs. your area and the U.S."
            )
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens the Compare tab")
    }

    // MARK: - Ask

    private var askLink: some View {
        NavigationLink {
            PersonalChatView(store: store)
        } label: {
            ActionRowLabel(
                systemImage: "bubble.left.and.text.bubble.right",
                title: askTitle,
                subtitle: "A calm, plain explanation — no judgment"
            )
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens Ask DebtShield about your month")
    }

    private var askTitle: String {
        switch plan.status {
        case .over, .tight: return "Ask why it's tight"
        default: return "Ask about your month"
        }
    }

    // MARK: - Breakdown

    private var breakdownCard: some View {
        Card {
            SectionHeader(title: "Where it goes")
            ForEach(plan.segments) { segment in
                HStack(spacing: Theme.Spacing.regular) {
                    Circle()
                        .fill(Theme.essentialColor(segment.kind))
                        .frame(width: 12, height: 12)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(segment.label)
                            .font(Theme.Typography.body)
                        if let share = plan.share(of: segment) {
                            Text("\(Int((share * 100).rounded()))% of income")
                                .font(Theme.Typography.caption)
                                .foregroundStyle(Theme.secondaryText)
                        }
                    }
                    Spacer()
                    Text(money(segment.amount))
                        .font(Theme.Typography.money())
                        .foregroundStyle(.primary)
                }
                .frame(minHeight: Theme.minimumTapTarget)
                .accessibilityElement(children: .combine)
            }

            Divider()

            HStack {
                Text(leftoverLabel)
                    .font(Theme.Typography.body.weight(.semibold))
                Spacer()
                if let left = plan.moneyLeft {
                    Text(headlineAmount(left))
                        .font(Theme.Typography.money())
                        .foregroundStyle(Theme.statusColor(plan.status ?? .okay))
                }
            }
            .frame(minHeight: 32)
        }
    }

    private var leftoverLabel: String {
        guard let left = plan.moneyLeft else { return "Left over" }
        return left >= 0 ? "Left over" : "Over by"
    }

    // MARK: - Edit

    private var editButton: some View {
        Button {
            isEditing = true
        } label: {
            Label("Edit your numbers", systemImage: "slider.horizontal.3")
                .font(Theme.Typography.body.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: Theme.minimumTapTarget)
        }
        .buttonStyle(.bordered)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.comfortable) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 40))
                .foregroundStyle(Theme.brand)
                .frame(width: 96, height: 96)
                .background(Circle().fill(Theme.iconWell(Theme.brand)))
                .accessibilityHidden(true)

            Text("See where your money stands")
                .font(Theme.Typography.title)
                .multilineTextAlignment(.center)

            Text("Add a few numbers and we'll show you, in plain dollars, how much room you have this month. Everything stays on your phone.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)

            Button {
                isEditing = true
            } label: {
                Text("Add your numbers")
                    .font(Theme.Typography.body.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: Theme.minimumTapTarget)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, Theme.Spacing.tight)
        }
        .padding(Theme.Spacing.section)
        .frame(maxWidth: .infinity)
        .padding(.top, Theme.Spacing.section)
    }

    private func money(_ value: Double) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }
}

#if DEBUG
#Preview("Filled — tight") {
    NavigationStack { SafeLineView(store: .preview(.sampleTight), onCompare: {}) }
}

#Preview("Filled — over") {
    NavigationStack { SafeLineView(store: .preview(.sampleOver), onCompare: {}) }
}

#Preview("With history") {
    NavigationStack { SafeLineView(store: .previewWithHistory(), onCompare: {}) }
}

#Preview("Empty") {
    NavigationStack { SafeLineView(store: .preview(.empty), onCompare: {}) }
}
#endif
