import SwiftUI

/// How the Financial Distress Index is built, and what it cannot do.
///
/// Figures are read from the live dataset and from `RiskScoring` rather than
/// written into the copy, so this screen cannot drift out of step with the
/// scoring engine the way a hand-written methodology page would.
struct MethodologyView: View {
    let dataset: Dataset

    private var weights: [DriverKind: Double] {
        RiskScoring.normalisedWeights(for: dataset.capabilities)
    }

    private var measured: [DriverKind] {
        DriverKind.allCases
            .filter { dataset.capabilities.measuredDrivers.contains($0) }
            .sorted { (weights[$0] ?? 0) > (weights[$1] ?? 0) }
    }

    private var unmeasured: [DriverKind] {
        DriverKind.allCases.filter { !dataset.capabilities.measuredDrivers.contains($0) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                summaryCard
                stepsCard
                weightsCard
                bandsCard
                dataCard
                limitationsCard
                EducationalDisclaimer()
            }
            .padding(Theme.Spacing.comfortable)
        }
        .background(Theme.screenGradient)
        .navigationTitle("Methodology")
        .navigationBarTitleDisplayMode(.large)
    }

    private var summaryCard: some View {
        Card {
            SectionHeader(title: "In one paragraph")
            Text("Each county's public statistics are converted to 0–100 sub-scores, one per risk driver. Those sub-scores are combined with fixed weights into the Financial Distress Index, also 0–100. The formula is the same for every county and never changes between runs, so two counties with identical figures always get identical scores.")
                .font(.subheadline)
        }
    }

    private var stepsCard: some View {
        Card {
            SectionHeader(title: "How a score is built")
            step(1, "Read the county's figures", "Income, rent, rent burden, poverty, and unemployment come from the bundled Census file.")
            step(2, "Scale each one to 0–100", "Every indicator is placed on a common scale using fixed low and high reference points, so figures measured in dollars and percentages can be combined.")
            step(3, "Combine them into drivers", "Related indicators are weighted together into a driver score — rent burden and rent-to-income form the housing driver, for example.")
            step(4, "Weight the drivers", "Driver scores are combined into the final index using the weights below.")
            step(5, "Band the result", "The index is labelled low, medium, or high risk.")
        }
    }

    private func step(_ number: Int, _ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.regular) {
            Text("\(number)")
                .font(.subheadline.weight(.bold).monospacedDigit())
                .foregroundStyle(Theme.brand)
                .frame(width: 24, alignment: .trailing)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(body)
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(number). \(title)")
        .accessibilityValue(body)
    }

    private var weightsCard: some View {
        Card {
            SectionHeader(
                title: "Weights",
                subtitle: "How much each driver contributes for this dataset"
            )

            ForEach(measured) { driver in
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(driver.title)
                            .font(.subheadline.weight(.semibold))
                        Text(driver.whyThisMatters)
                            .font(.footnote)
                            .foregroundStyle(Theme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: Theme.Spacing.regular)
                    Text("\(Int(((weights[driver] ?? 0) * 100).rounded()))%")
                        .font(.subheadline.weight(.bold).monospacedDigit())
                }
                .padding(.vertical, Theme.Spacing.tight)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(driver.title)
                .accessibilityValue("\(Int(((weights[driver] ?? 0) * 100).rounded())) percent of the score. \(driver.whyThisMatters)")
            }

            if !unmeasured.isEmpty {
                Divider()
                Text("**\(ListFormatter.localizedString(byJoining: unmeasured.map(\.title)))** are part of the design but carry no weight here, because this dataset has no source for them. The remaining weights are rescaled to add up to 100% rather than leaving a gap — so no county is scored on data DebtShield AI does not have.")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
    }

    private var bandsCard: some View {
        Card {
            SectionHeader(title: "Risk bands")
            ForEach(RiskLevel.allCases) { level in
                HStack(alignment: .top, spacing: Theme.Spacing.regular) {
                    Image(systemName: level.symbolName)
                        .foregroundStyle(Theme.riskColor(level))
                        .frame(width: 24)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(level.label) — \(bandRange(level))")
                            .font(.subheadline.weight(.semibold))
                        Text(level.plainEnglish)
                            .font(.footnote)
                            .foregroundStyle(Theme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.vertical, 4)
                .accessibilityElement(children: .combine)
            }
            Text("The thresholds are a presentational choice by this project, not an official standard.")
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
        }
    }

    private func bandRange(_ level: RiskLevel) -> String {
        switch level {
        case .low: return "below 35"
        case .medium: return "35 to 65"
        case .high: return "65 and above"
        }
    }

    private var dataCard: some View {
        Card {
            SectionHeader(title: "Where the data comes from")
            Text(dataset.sourceDescription)
                .font(.subheadline.weight(.semibold))
            Text("The U.S. Census Bureau's American Community Survey 5-Year estimates cover \(dataset.counties.count.formatted(.number)) counties across \(dataset.states.count) states. Five-year estimates average several years of responses, which makes small-area figures more reliable but slower to reflect change.")
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
            Text("\(dataset.scoredCounties.count.formatted(.number)) counties have enough data to score. \(dataset.unscoredCounties.count) do not — the Census does not publish income estimates for the very smallest populations. Those counties stay in the app, marked as unscored, rather than being dropped.")
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
        }
    }

    private var limitationsCard: some View {
        Card {
            HStack(spacing: Theme.Spacing.tight) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Theme.riskColor(.medium))
                    .accessibilityHidden(true)
                Text("What this cannot tell you")
                    .font(.title3.weight(.bold))
                    .accessibilityAddTraits(.isHeader)
            }

            limitation("It describes counties, not people.",
                       "A county with a low score still contains households in serious difficulty. Averages hide the range inside them.")
            limitation("The weights are a judgement.",
                       "There is no objective correct weighting for housing against cost of living. Different reasonable choices would reorder some counties.")
            limitation("Three drivers are missing.",
                       "Debt, energy, and food access have no data source in this dataset, so the index measures less than it was designed to.")
            limitation("It is not a forecast.",
                       "The index reflects conditions when the data was collected. Nothing here projects forward.")
            limitation("The machine-learning models do not power the app.",
                       "They were trained during research and are reported on the Model Performance screen for transparency. The index is a fixed formula, chosen because it can explain itself.")
        }
    }

    private func limitation(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(body)
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
