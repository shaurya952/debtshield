import SwiftUI

/// The home screen. The first thing a person sees, and the heart of the app.
///
/// It answers one question in dollars — *how does this month stand?* — with the
/// Safe Line bar, a single headline figure, and a calm one-line verdict. No
/// score, no grade, no jargon. If nothing has been entered yet it shows a warm
/// invitation rather than an empty chart.
///
/// It deliberately depends only on `MoneyPlanStore`, never on the county
/// `Dataset`. A person's budget must never wait on — or fail with — the load of
/// 3,000 counties. The housing comparison layer arrives later and is purely
/// additive on top of this.
struct SafeLineView: View {
    let store: MoneyPlanStore
    @State private var isEditing = false

    private var plan: MoneyPlan { store.plan }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                if plan.isComplete {
                    resultCard
                    askLink
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

    // MARK: - Result

    @ViewBuilder
    private var resultCard: some View {
        let status = plan.status ?? .okay
        Card {
            // Eyebrow: the situation, in words and colour.
            Text(status.headline)
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.statusColor(status))

            // The one number that matters.
            if let left = plan.moneyLeft {
                Text(headlineAmount(left))
                    .font(Theme.Typography.heroMoney)
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                Text(left >= 0 ? "left this month" : "short this month")
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.secondaryText)
            }

            SafeLineBar(plan: plan)
                .padding(.top, Theme.Spacing.tight)
        }
    }

    private func headlineAmount(_ left: Double) -> String {
        let magnitude = left.magnitude.formatted(.currency(code: "USD").precision(.fractionLength(0)))
        return left >= 0 ? magnitude : "−\(magnitude)"
    }

    // MARK: - Ask

    private var askLink: some View {
        NavigationLink {
            PersonalChatView(store: store)
        } label: {
            HStack(spacing: Theme.Spacing.regular) {
                Image(systemName: "bubble.left.and.text.bubble.right")
                    .font(.title3)
                    .foregroundStyle(Theme.brand)
                    .frame(width: 38, height: 38)
                    .background(Theme.iconWell(Theme.brand), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(askTitle)
                        .font(Theme.Typography.body.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("A calm, plain explanation — no judgment")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.secondaryText)
                    .accessibilityHidden(true)
            }
            .padding(Theme.Spacing.comfortable)
            .frame(maxWidth: .infinity, minHeight: Theme.minimumTapTarget)
            .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
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
                    Text(segment.label)
                        .font(Theme.Typography.body)
                    Spacer()
                    Text(money(segment.amount))
                        .font(Theme.Typography.money())
                        .foregroundStyle(.primary)
                }
                .frame(minHeight: 32)
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
                .font(.system(size: 44))
                .foregroundStyle(Theme.brand)
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
    NavigationStack { SafeLineView(store: .preview(.sampleTight)) }
}

#Preview("Filled — over") {
    NavigationStack { SafeLineView(store: .preview(.sampleOver)) }
}

#Preview("Empty") {
    NavigationStack { SafeLineView(store: .preview(.empty)) }
}
#endif
