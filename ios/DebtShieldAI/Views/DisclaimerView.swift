import SwiftUI

/// The fine print, in plain language.
struct DisclaimerView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                Card {
                    HStack(spacing: Theme.Spacing.tight) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(Theme.statusColor(.tight))
                            .accessibilityHidden(true)
                        Text("A picture, not advice")
                            .font(.title3.weight(.bold))
                            .accessibilityAddTraits(.isHeader)
                    }
                    Text("Headroom shows you your own numbers clearly. It isn't financial advice, legal advice, or benefits advice, and it can't see your full situation.")
                        .font(Theme.Typography.subheadline)
                }

                DisclaimerPoint(
                    title: "It's a starting point",
                    message: "What you see here is a clear look at your month — not a recommendation about your money, your housing, your debts, or your benefits. It's no substitute for a qualified adviser, a housing counsellor, or a benefits caseworker."
                )

                DisclaimerPoint(
                    title: "The comparisons are rough markers",
                    message: "\"Typical\" rent, energy, and food figures are broad public averages. Real costs vary enormously from home to home, so treat them as a gentle reference, never a target you have to hit."
                )

                DisclaimerPoint(
                    title: "The safe line is a guideline",
                    message: "Keeping essentials under about 55% of income, and debt payments under 20%, are common rules of thumb — not rules. Your right numbers depend on your life."
                )

                DisclaimerPoint(
                    title: "What-ifs are estimates",
                    message: "When you try a change — \"what if rent dropped $200\" — the app just recalculates your numbers. That's an estimate of your budget, not a prediction of what will happen."
                )

                DisclaimerPoint(
                    title: "No warranty",
                    message: "This app is provided as is, without any guarantee of accuracy or fitness for a particular purpose. Please don't rely on it alone for big decisions."
                )

                Card {
                    SectionHeader(title: "If you need real help")
                    Text("In the United States, dialling **211** connects you to local assistance with housing, utilities, food, and benefits. HUD-approved housing counsellors offer free guidance, and nonprofit credit counsellors offer free or low-cost debt reviews.")
                        .font(Theme.Typography.subheadline)
                    Text("This app can't refer you, check your eligibility, or contact anyone for you — but those services can.")
                        .font(Theme.Typography.footnote)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            .padding(Theme.Spacing.comfortable)
        }
        .background(Theme.screenGradient)
        .navigationTitle("The fine print")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct DisclaimerPoint: View {
    let title: String
    let message: String

    var body: some View {
        Card {
            Text(title)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            Text(message)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}
