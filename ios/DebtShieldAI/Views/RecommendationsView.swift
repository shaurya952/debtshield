import SwiftUI

/// Phase 4 Recommendations.
///
/// Two audiences read the same finding differently, so the screen switches
/// between guidance aimed at people who can change policy and guidance aimed at
/// people living with the result. The Ask DebtShield chatbot lands here in
/// Phase 8.
/// Pushed from County Profile, which only offers the link for scored counties —
/// so this view can take a concrete county and does not need empty states.
struct RecommendationsView: View {
    let dataset: Dataset
    let county: ScoredCounty

    @AppStorage("debtshield.recommendationAudience")
    private var audienceRaw: String = RecommendationAudience.policymakers.rawValue

    private var audience: RecommendationAudience {
        RecommendationAudience(rawValue: audienceRaw) ?? .policymakers
    }

    var body: some View {
        content(for: county)
            .background(Theme.screenGradient)
            .navigationTitle("Recommendations")
            .navigationBarTitleDisplayMode(.inline)
    }

    private func content(for county: ScoredCounty) -> some View {
        let standings = dataset.standings(for: county)
        let recommendations = RecommendationEngine.recommendations(for: standings, audience: audience)
        let nothingElevated = !standings.contains { $0.severity.warrantsAction }

        return ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                audiencePicker(for: county)

                if nothingElevated {
                    stableCard
                }

                ForEach(recommendations) { recommendation in
                    recommendationCard(recommendation)
                }

                notAssessedNote(for: county)
                adviceDisclaimer
            }
            .padding(Theme.Spacing.comfortable)
        }
    }

    // MARK: - Audience

    private func audiencePicker(for county: ScoredCounty) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 2) {
                Text(county.displayName)
                    .font(.title3.weight(.bold))
                    .accessibilityAddTraits(.isHeader)
                if let riskLevel = county.riskLevel, let index = county.index {
                    Text("\(riskLevel.label) risk · index \(index.scoreText)")
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                }
            }

            Picker("Written for", selection: $audienceRaw) {
                ForEach(RecommendationAudience.allCases) { option in
                    Text(option.shortTitle).tag(option.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Written for")
            .accessibilityHint("Switches between guidance for policymakers and guidance for residents")

            Text(audience.introduction)
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
        }
    }

    // MARK: - Cards

    private var stableCard: some View {
        Card {
            SectionHeader(title: "Nothing stands out")
            Text(RecommendationEngine.stableSummary)
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
            Text("The area below is still this county's strongest relative pressure, shown for context.")
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
        }
    }

    private func recommendationCard(_ recommendation: Recommendation) -> some View {
        Card {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.tight) {
                Text(recommendation.driver.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.secondaryText)
                Spacer(minLength: Theme.Spacing.tight)
                SeverityBadge(severity: recommendation.severity)
            }

            Text(recommendation.headline)
                .font(.title3.weight(.bold))
                .accessibilityAddTraits(.isHeader)

            Text(recommendation.rationale)
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)

            Divider()

            VStack(alignment: .leading, spacing: Theme.Spacing.regular) {
                ForEach(Array(recommendation.actions.enumerated()), id: \.offset) { _, action in
                    HStack(alignment: .top, spacing: Theme.Spacing.tight) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 5))
                            .padding(.top, 7)
                            .foregroundStyle(Theme.secondaryText)
                            .accessibilityHidden(true)
                        Text(action)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    /// Says plainly that three drivers were never assessed, so an absence of
    /// debt or energy guidance is not read as an all-clear.
    @ViewBuilder
    private func notAssessedNote(for county: ScoredCounty) -> some View {
        let unmeasured = county.drivers.filter { !$0.isMeasured }
        if !unmeasured.isEmpty {
            Card {
                SectionHeader(title: "Not assessed here")
                Text(unmeasured.map(\.title).joined(separator: ", ") + " could not be evaluated for this county, because the dataset has no source for them. Their absence from this page is not a sign that they are fine.")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
    }

    /// Stronger than the standard footer: this screen is the one most likely to
    /// be mistaken for advice, so it says otherwise in full.
    private var adviceDisclaimer: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.tight) {
            Image(systemName: "exclamationmark.circle")
                .foregroundStyle(Theme.secondaryText)
                .accessibilityHidden(true)
            Text("These are general, educational descriptions of programme types that commonly exist in the United States. They are not legal, financial, or benefits advice, are not tailored to any individual, and eligibility rules differ by state and county. Check with the relevant agency before relying on any of it.")
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
        }
        .padding(Theme.Spacing.comfortable)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
    }
}
