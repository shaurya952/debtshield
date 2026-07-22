import SwiftUI

/// Hub for the national-level screens.
///
/// Introduced in Phase 7, when Model Performance gave the Risk Map a companion.
/// Phase 8 adds Ask DebtShield as a third row. Keeping these behind one tab is
/// what holds the tab bar at five — past that, iOS collapses tabs into a system
/// "More" list.
struct InsightsView: View {
    let dataset: Dataset
    let searchIndex: CountySearchIndex
    let selection: SelectionStore
    var onSelectCounty: (ScoredCounty) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                Card {
                    SectionHeader(title: "Risk Map")
                    NavigationLink {
                        RiskMapView(dataset: dataset, onSelectCounty: onSelectCounty)
                    } label: {
                        DetailNavigationRow(
                            title: "Every state",
                            subtitle: "Compare all 51 states, then drill into their counties",
                            systemImage: "map"
                        )
                    }
                    .buttonStyle(.plain)
                }

                Card {
                    SectionHeader(title: "Ask DebtShield")
                    NavigationLink {
                        ChatbotView(dataset: dataset, searchIndex: searchIndex, selection: selection)
                    } label: {
                        DetailNavigationRow(
                            title: "Ask a question",
                            subtitle: "Explains risk levels, drivers, and how the score works, in plain language",
                            systemImage: "bubble.left.and.text.bubble.right"
                        )
                    }
                    .buttonStyle(.plain)
                }

                Card {
                    SectionHeader(title: "The model")
                    NavigationLink {
                        ModelPerformanceView()
                    } label: {
                        DetailNavigationRow(
                            title: "Model performance",
                            subtitle: "How the research models scored, and what those scores do and do not show",
                            systemImage: "chart.dots.scatter"
                        )
                    }
                    .buttonStyle(.plain)
                }

                summaryCard

                EducationalDisclaimer()
            }
            .padding(Theme.Spacing.comfortable)
        }
        .background(Theme.screenGradient)
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.large)
    }

    /// A little national context so the hub carries information rather than
    /// being only a menu.
    private var summaryCard: some View {
        Card {
            SectionHeader(
                title: "What is in this data",
                subtitle: dataset.sourceDescription
            )
            Text("\(dataset.counties.count.formatted(.number)) counties across \(dataset.states.count) states. \(dataset.scoredCounties.count.formatted(.number)) have enough Census data to score; \(dataset.unscoredCounties.count) do not.")
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
            Text("The Financial Distress Index is a rule-based formula, not a machine-learning prediction. Model Performance explains how the two relate.")
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
        }
    }
}
