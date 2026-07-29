import SwiftUI

/// Plain-language explanation of what the app does — no formulas, no jargon.
struct HowItWorksView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                Card {
                    Text("The whole idea")
                        .font(Theme.Typography.title)
                        .accessibilityAddTraits(.isHeader)
                    Text("Money feels calmer when you can see it. You enter what comes in and what goes out each month, and DebtShield shows you — in plain dollars — how much room you have. No score out of 100, no grade, no judgment.")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Card {
                    SectionHeader(title: "The safe line")
                    Text("Your income is the bar. Your essentials — rent or mortgage, food, energy, debt payments — fill it up from the left. Whatever's left is your room for the month.")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("The dashed line marks where essentials are best kept under — about 55% of what comes in. Below it, you've usually got breathing room. Past it, the month gets tight, and the bar shows it.")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Card {
                    SectionHeader(
                        title: "How your costs compare",
                        subtitle: "Rough markers from public data — guides, not targets"
                    )
                    sourceRow("Rent", "Typical rent where you live, from the U.S. Census Bureau (American Community Survey).")
                    sourceRow("Energy", "Typical monthly electricity bill for your state, from the U.S. Energy Information Administration (EIA), 2024.")
                    sourceRow("Food", "Typical monthly food spending for your income, from the Bureau of Labor Statistics (BLS) Consumer Expenditure Survey, 2024.")
                    sourceRow("Debt", "A common guideline: keeping non-housing debt payments under 20% of income.")
                    Text("These are broad averages. Real life varies a lot, so treat them as a gentle reference, never a target you have to hit.")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Card {
                    SectionHeader(
                        title: "The year ahead",
                        subtitle: "Where the odds on your home screen come from"
                    )
                    Text("Nobody can know the future, so we don't try to guess it once. Instead we play your month out hundreds of times over. In some of those runs a bill lands high or a surprise cost hits; in others everything stays calm.")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Then we count: in how many of those runs did you end up short? That share is the \"chance of going into debt\" you see. The range shows where your savings could land — from a rough stretch to a good one. Track a few months and it stops using typical U.S. swings and starts using your own.")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Card {
                    SectionHeader(title: "What it can't do")
                    Text("DebtShield isn't financial or legal advice, and it can't see your full situation. It's a clear, private picture of your month — a starting point, not a decision. For real help, dialling **211** in the United States connects you to local assistance, and HUD-approved counsellors offer free money and housing guidance.")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(Theme.Spacing.comfortable)
        }
        .background(Theme.screenGradient)
        .navigationTitle("How it works")
        .navigationBarTitleDisplayMode(.large)
    }

    private func sourceRow(_ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.regular) {
            Image(systemName: "circle.fill")
                .font(.system(size: 7))
                .foregroundStyle(Theme.brand)
                .padding(.top, 6)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.Typography.body.weight(.semibold))
                Text(body)
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
#Preview {
    NavigationStack { HowItWorksView() }
}
#endif
