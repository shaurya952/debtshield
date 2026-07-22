import SwiftUI
import Charts

/// Phase 4 Risk Drivers.
///
/// The Streamlit page showed a ranked bar chart and a table of the same five
/// numbers. This adds the two things that make the ranking mean something: how
/// each driver compares with every other county, and what inputs produced the
/// score.
/// Pushed from County Profile, which only offers the link for scored counties —
/// so this view can take a concrete county and does not need empty states.
struct RiskDriversView: View {
    let dataset: Dataset
    let county: ScoredCounty

    var body: some View {
        content(for: county)
            .background(Theme.screenGradient)
            .navigationTitle("Risk Drivers")
            .navigationBarTitleDisplayMode(.inline)
    }

    private func content(for county: ScoredCounty) -> some View {
        let standings = dataset.standings(for: county)

        return ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                header(for: county, standings: standings)
                rankingCard(standings)
                ForEach(standings) { standing in
                    breakdownCard(standing, county: county)
                }
                unmeasuredCard(for: county)
                EducationalDisclaimer()
            }
            .padding(Theme.Spacing.comfortable)
        }
    }

    // MARK: - Header

    private func header(for county: ScoredCounty, standings: [DriverStanding]) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 2) {
                Text(county.county)
                    .font(.title3.weight(.bold))
                    .accessibilityAddTraits(.isHeader)
                Text(county.state)
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
            }

            if let top = standings.first {
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Strongest pressure: \(top.kind.title)")
                        .font(.subheadline.weight(.semibold))
                    Text(top.comparisonSentence)
                        .font(.footnote)
                        .foregroundStyle(Theme.secondaryText)
                    Text(top.kind.whyThisMatters)
                        .font(.footnote)
                        .foregroundStyle(Theme.secondaryText)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    // MARK: - Ranking

    private func rankingCard(_ standings: [DriverStanding]) -> some View {
        Card {
            SectionHeader(
                title: "Ranked drivers",
                subtitle: "Scored 0 to 100. The marker shows the national median for each driver."
            )

            Chart {
                ForEach(standings) { standing in
                    BarMark(
                        x: .value("Score", standing.score),
                        y: .value("Driver", standing.kind.title)
                    )
                    .foregroundStyle(Theme.brand)
                    .accessibilityLabel(standing.kind.title)
                    .accessibilityValue("\(standing.score.scoreText) out of 100. \(standing.comparisonSentence)")

                    // National median reference, so a low-looking score is
                    // readable as high-for-the-country when it is.
                    //
                    // A PointMark, not a RuleMark: each driver has its own
                    // median, and a full-height rule would draw the housing
                    // median straight through the cost-of-living row.
                    PointMark(
                        x: .value("National median", standing.nationalMedian),
                        y: .value("Driver", standing.kind.title)
                    )
                    .symbol(.diamond)
                    .symbolSize(90)
                    .foregroundStyle(Theme.secondaryText)
                    .accessibilityLabel("\(standing.kind.title) national median")
                    .accessibilityValue(standing.nationalMedian.scoreText)
                }
            }
            .chartXScale(domain: 0...100)
            .chartXAxis { AxisMarks(values: [0, 25, 50, 75, 100]) }
            .frame(height: max(140, CGFloat(standings.count) * 64))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Ranked driver chart")
            .accessibilityValue(
                standings.map { "\($0.kind.title) \($0.score.scoreText) out of 100" }
                    .joined(separator: ". ")
            )

            ForEach(standings) { standing in
                DriverStandingRow(standing: standing)
            }
        }
    }

    // MARK: - Breakdown

    /// "How this score is built" — the component weights and the raw figure
    /// behind each one.
    private func breakdownCard(_ standing: DriverStanding, county: ScoredCounty) -> some View {
        let components = RiskScoring.components(of: standing.kind, for: county.record)
        let unmeasured = components.filter { !$0.isMeasured }

        return Card {
            SectionHeader(
                title: "How \(standing.kind.title.lowercased()) is calculated",
                subtitle: "Weighted inputs that produce a score of \(standing.score.scoreText)"
            )

            ForEach(components) { component in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(component.label)
                            .font(.subheadline)
                        Spacer(minLength: Theme.Spacing.tight)
                        Text("\(component.weightPercent)%")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(Theme.secondaryText)
                    }
                    if let score = component.score {
                        HStack(spacing: Theme.Spacing.tight) {
                            Text("Scores \(score.scoreText)")
                                .font(.footnote)
                                .foregroundStyle(Theme.secondaryText)
                            if let value = component.sourceValue {
                                Text("· from \(value)")
                                    .font(.footnote)
                                    .foregroundStyle(Theme.secondaryText)
                            }
                        }
                    } else {
                        Text("No data source — counts as zero")
                            .font(.footnote)
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
                .padding(.vertical, Theme.Spacing.tight)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(component.label)
                .accessibilityValue(componentAccessibilityValue(component))
            }

            if !unmeasured.isEmpty {
                Divider()
                Text("Because \(unmeasured.count == 1 ? "one input has" : "\(unmeasured.count) inputs have") no data source, they contribute zero. That holds this driver's score below what it would otherwise be, for every county equally.")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
    }

    private func componentAccessibilityValue(_ component: RiskScoring.DriverComponent) -> String {
        guard let score = component.score else {
            return "Weighted \(component.weightPercent) percent. No data source, counts as zero."
        }
        let source = component.sourceValue.map { ", from \($0)" } ?? ""
        return "Weighted \(component.weightPercent) percent. Scores \(score.scoreText)\(source)."
    }

    // MARK: - Unmeasured drivers

    @ViewBuilder
    private func unmeasuredCard(for county: ScoredCounty) -> some View {
        let unmeasured = county.drivers.filter { !$0.isMeasured }
        if !unmeasured.isEmpty {
            Card {
                SectionHeader(
                    title: "Not assessed",
                    subtitle: "No data source in this dataset"
                )
                ForEach(unmeasured) { driver in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(driver.title)
                            .font(.subheadline.weight(.semibold))
                        Text(driver.kind.whyThisMatters)
                            .font(.footnote)
                            .foregroundStyle(Theme.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityElement(children: .combine)
                }
                Text("These are excluded from the Financial Distress Index rather than estimated, so no county is ranked on data DebtShield AI does not have.")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
    }
}

// MARK: - Standing row

/// One driver with its score, national standing, and a severity badge that
/// carries its meaning in text and shape as well as colour.
struct DriverStandingRow: View {
    let standing: DriverStanding

    /// At accessibility sizes the title, score, and badge cannot share a line
    /// without truncating, so they stack.
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if typeSize.isAccessibilitySize {
                Text(standing.kind.title)
                    .font(.subheadline.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: Theme.Spacing.tight) {
                    Text(standing.score.scoreText)
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                    SeverityBadge(severity: standing.severity)
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.tight) {
                    Text(standing.kind.title)
                        .font(.subheadline.weight(.semibold))
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: Theme.Spacing.tight)
                    Text(standing.score.scoreText)
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                    SeverityBadge(severity: standing.severity)
                }
            }
            Text(standing.comparisonSentence)
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, Theme.Spacing.tight)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(standing.kind.title)
        .accessibilityValue("\(standing.score.scoreText) out of 100. \(standing.severity.label). \(standing.comparisonSentence)")
    }
}

/// Severity shown as icon + words, never colour alone.
struct SeverityBadge: View {
    let severity: DriverSeverity

    var body: some View {
        Label {
            Text(severity.shortLabel)
                .font(.caption.weight(.semibold))
                .fixedSize(horizontal: true, vertical: true)
        } icon: {
            Image(systemName: severity.symbolName)
                .imageScale(.small)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, Theme.Spacing.tight)
        .padding(.vertical, 4)
        .background(tint.opacity(0.12), in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(severity.label)
    }

    private var tint: Color {
        switch severity {
        case .critical: return Theme.riskColor(.high)
        case .elevated: return Theme.riskColor(.medium)
        case .typical, .low: return Theme.riskColor(.low)
        }
    }
}

