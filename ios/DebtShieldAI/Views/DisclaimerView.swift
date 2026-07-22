import SwiftUI

/// The educational-use disclaimer in full.
struct DisclaimerView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                Card {
                    HStack(spacing: Theme.Spacing.tight) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(Theme.riskColor(.medium))
                            .accessibilityHidden(true)
                        Text("Educational use only")
                            .font(.title3.weight(.bold))
                            .accessibilityAddTraits(.isHeader)
                    }
                    Text("DebtShield AI is an educational and analytical tool. It is not financial advice, not legal advice, and not government-benefit advice.")
                        .font(.subheadline)
                }

                DisclaimerPoint(
                    title: "It is not advice",
                    message: "Nothing in this app is a recommendation about your money, your housing, your debts, or your benefits. It is not a substitute for a qualified financial adviser, a lawyer, a housing counsellor, or a benefits caseworker."
                )

                DisclaimerPoint(
                    title: "It describes places, not people",
                    message: "Every figure here is about a county as a whole. A county's score says nothing about any household inside it. Someone in a low-risk county can be in serious difficulty, and someone in a high-risk county can be perfectly secure."
                )

                DisclaimerPoint(
                    title: "The programmes described are general",
                    message: "Where the app mentions support such as rental assistance or energy help, it is describing types of programme that commonly exist in the United States. Eligibility, availability, and names differ by state and county, and programmes change. Always check with the relevant agency."
                )

                DisclaimerPoint(
                    title: "The scores are a project's own construction",
                    message: "The Financial Distress Index, its weights, and its risk thresholds were defined by this project. They are not an official measure and carry no standing with any government body or lender."
                )

                DisclaimerPoint(
                    title: "The data has limits",
                    message: "Figures come from Census survey estimates, which carry sampling error and lag behind current conditions. Three of the five risk drivers have no data source in this dataset. Two counties cannot be scored at all."
                )

                DisclaimerPoint(
                    title: "It does not predict anything",
                    message: "The index reflects conditions when the data was collected. The Scenario Simulator shows what the formula would produce under different figures — that is an estimate of the formula, not a forecast of events."
                )

                DisclaimerPoint(
                    title: "No warranty",
                    message: "This is a research prototype provided as is, without any guarantee of accuracy, completeness, or fitness for a particular purpose. Do not rely on it for consequential decisions."
                )

                Card {
                    SectionHeader(title: "If you need real help")
                    Text("In the United States, dialling **211** connects to local assistance with housing, utilities, food, and benefits. HUD-approved housing counselling agencies offer free guidance, and nonprofit credit counselling agencies offer free or low-cost debt reviews.")
                        .font(.subheadline)
                    Text("This app cannot refer you, check your eligibility, or contact anyone on your behalf.")
                        .font(.footnote)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            .padding(Theme.Spacing.comfortable)
        }
        .background(Theme.screenGradient)
        .navigationTitle("Disclaimer")
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
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}
