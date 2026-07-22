import SwiftUI
import Charts

/// Phase 1 dashboard: national snapshot, risk distribution, and the counties at
/// each end of the index.
struct DashboardView: View {
    let dataset: Dataset
    /// Set by the tab shell so list rows open the County Profile. Optional so
    /// the view still previews standalone.
    var onSelectCounty: ((ScoredCounty) -> Void)?

    @ScaledMetric(relativeTo: .largeTitle) private var heroNumberSize: CGFloat = 30

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                heroHeader
                summaryGrid
                riskLegend
                distributionCard
                watchlistCard
                safestCard
                unscoredCard
                coverageNote
                EducationalDisclaimer()
            }
            .padding(Theme.Spacing.comfortable)
        }
        .background(Theme.screenGradient)
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Hero

    /// Brand header. Carries the mark, the headline figure, and the source in
    /// one block so the dashboard opens with something with presence rather
    /// than a grid of grey cards.
    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.comfortable) {
            BrandLockup(size: 38, onColor: true)

            VStack(alignment: .leading, spacing: 2) {
                Text("Financial pressure across")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.white)
                Text("\(dataset.counties.count.formatted(.number)) U.S. counties")
                    .font(.system(size: heroNumberSize, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: Theme.Spacing.tight) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(Theme.accentWarm)
                    .accessibilityHidden(true)
                Text("U.S. Census data, built in — nothing leaves your device")
                    .font(.footnote)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Theme.Spacing.comfortable)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.brandGradient, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Theme.brand.opacity(0.28), radius: 16, x: 0, y: 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("DebtShield AI")
        .accessibilityValue("Financial pressure across \(dataset.counties.count.formatted(.number)) U.S. counties. Census data is built in and nothing leaves your device.")
    }

    // MARK: - Summary

    /// Two columns on a phone, and the grid reflows as Dynamic Type grows so
    /// large-text users get one full-width card per row instead of clipping.
    private var summaryGrid: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 172), spacing: Theme.Spacing.regular)],
            spacing: Theme.Spacing.regular
        ) {
            StatCard(
                label: "Counties",
                value: dataset.counties.count.formatted(.number),
                detail: countiesDetail,
                systemImage: "building.2",
                tint: Theme.brand
            )
            StatCard(
                label: "Average index",
                value: dataset.averageIndex.scoreText,
                detail: "out of 100",
                systemImage: "chart.line.uptrend.xyaxis",
                tint: Theme.brand
            )
            StatCard(
                label: "High risk",
                value: dataset.count(of: .high).formatted(.number),
                detail: "\(dataset.count(of: .medium).formatted(.number)) medium risk",
                systemImage: RiskLevel.high.symbolName,
                tint: Theme.riskColor(.high)
            )
            StatCard(
                label: "Low risk",
                value: dataset.count(of: .low).formatted(.number),
                detail: "below the 35 threshold",
                systemImage: RiskLevel.low.symbolName,
                tint: Theme.riskColor(.low)
            )
        }
    }

    /// Every county in the country is listed. When some cannot be scored, the
    /// card says so rather than quietly reporting a smaller total.
    private var countiesDetail: String {
        let unscored = dataset.unscoredCounties.count
        guard unscored > 0 else { return "Across \(dataset.states.count) states" }
        return "\(dataset.scoredCounties.count.formatted(.number)) scored · \(unscored) unscored"
    }

    // MARK: - Legend

    private var riskLegend: some View {
        Card {
            SectionHeader(title: "What the risk levels mean")
            ForEach(RiskLevel.allCases) { level in
                HStack(alignment: .top, spacing: Theme.Spacing.regular) {
                    Image(systemName: level.symbolName)
                        .foregroundStyle(Theme.riskColor(level))
                        .frame(width: 24)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(level.label)
                            .font(.subheadline.weight(.semibold))
                        Text(level.plainEnglish)
                            .font(.footnote)
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    // MARK: - Distribution chart

    private var distributionCounts: [(level: RiskLevel, count: Int)] {
        RiskLevel.allCases.map { ($0, dataset.count(of: $0)) }
    }

    /// A chart is a picture; the sentence beneath it is the same information in
    /// words. Both are always present — the text summary is not a fallback that
    /// only VoiceOver users get.
    private var distributionSummary: String {
        let parts = distributionCounts.map { "\($0.count.formatted(.number)) \($0.level.label.lowercased()) risk" }
        var summary = "Of \(dataset.scoredCounties.count.formatted(.number)) scored counties: "
            + parts.joined(separator: ", ") + "."
        let unscored = dataset.unscoredCounties.count
        if unscored > 0 {
            summary += " A further \(unscored) \(unscored == 1 ? "county has" : "counties have") too little Census data to score."
        }
        return summary
    }

    private var distributionCard: some View {
        Card {
            SectionHeader(
                title: "Risk distribution",
                subtitle: "How the \(dataset.scoredCounties.count.formatted(.number)) scored counties split across risk levels"
            )

            Chart(distributionCounts, id: \.level) { item in
                BarMark(
                    x: .value("Risk level", item.level.label),
                    y: .value("Counties", item.count)
                )
                .foregroundStyle(Theme.riskColor(item.level))
                .annotation(position: .top) {
                    Text(item.count.formatted(.number))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                }
                .accessibilityLabel(item.level.label)
                .accessibilityValue("\(item.count.formatted(.number)) counties")
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 200)
            .accessibilityLabel("Risk distribution chart")

            Text(distributionSummary)
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
        }
    }

    // MARK: - Lists

    private var watchlistCard: some View {
        Card {
            SectionHeader(
                title: "Top 10 highest risk",
                subtitle: "Counties with the highest Financial Distress Index"
            )
            countyList(Array(dataset.highestRisk.prefix(10)))
        }
    }

    private var safestCard: some View {
        Card {
            SectionHeader(
                title: "Top 10 lowest risk",
                subtitle: "Counties with the lowest Financial Distress Index"
            )
            countyList(Array(dataset.lowestRisk.prefix(10)))
        }
    }

    /// Counties the Census cannot support a score for. Listed explicitly so
    /// they are visible somewhere rather than only findable by search — a
    /// county missing from every list is indistinguishable from a county the
    /// app forgot.
    @ViewBuilder
    private var unscoredCard: some View {
        let unscored = dataset.unscoredCounties
        if !unscored.isEmpty {
            Card {
                SectionHeader(
                    title: "Counties without a score",
                    subtitle: "Included in the app, but the Census publishes too little data to score them"
                )
                countyList(unscored)
                Text("These are typically the least-populous counties in the country. No score does not mean low risk.")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
    }

    private func countyList(_ counties: [ScoredCounty]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(counties.enumerated()), id: \.element.id) { position, county in
                if position > 0 {
                    Divider()
                }
                if let onSelectCounty {
                    Button {
                        onSelectCounty(county)
                    } label: {
                        CountyRow(rank: position + 1, county: county, isTappable: true)
                    }
                    .buttonStyle(.plain)
                } else {
                    CountyRow(rank: position + 1, county: county)
                }
            }
        }
    }

    // MARK: - Coverage

    /// Says out loud which drivers the bundled dataset can and cannot measure.
    /// The Streamlit version quietly substituted defaults here, which made
    /// every county show the same Energy and Food Access score.
    private var coverageNote: some View {
        let measured = DriverKind.allCases.filter { dataset.capabilities.measuredDrivers.contains($0) }
        let unmeasured = DriverKind.allCases.filter { !dataset.capabilities.measuredDrivers.contains($0) }

        return Card {
            SectionHeader(title: "What this data covers")
            Text(dataset.sourceDescription)
                .font(.subheadline)

            Text("Measured: " + measured.map(\.title).joined(separator: ", "))
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)

            if !unmeasured.isEmpty {
                Text("Not yet measured: " + unmeasured.map(\.title).joined(separator: ", ") + ". These are excluded from the index rather than filled with an assumed value, so no county is scored on data DebtShield AI does not have.")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
    }
}

// MARK: - Row

/// One county in a ranked list. The whole row is a single VoiceOver element
/// with a complete sentence, and it clears the 44pt minimum height.
struct CountyRow: View {
    let rank: Int
    let county: ScoredCounty
    var isTappable: Bool = false

    var body: some View {
        HStack(spacing: Theme.Spacing.regular) {
            Text("\(rank)")
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(Theme.secondaryText)
                .frame(minWidth: 24, alignment: .trailing)

            VStack(alignment: .leading, spacing: 4) {
                Text(county.county)
                    .font(.body.weight(.medium))
                    .fixedSize(horizontal: false, vertical: true)
                Text(county.state)
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)
            }

            Spacer(minLength: Theme.Spacing.tight)

            VStack(alignment: .trailing, spacing: 4) {
                if let index = county.index, let riskLevel = county.riskLevel {
                    Text(index.scoreText)
                        .font(.body.weight(.semibold).monospacedDigit())
                    RiskBadge(level: riskLevel, compact: true)
                } else {
                    UnscoredBadge()
                }
            }

            if isTappable {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.secondaryText)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, Theme.Spacing.regular)
        .frame(minHeight: Theme.minimumTapTarget)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rank \(rank). \(county.accessibilitySummary)")
        .accessibilityHint(isTappable ? "Opens this county's profile" : "")
        .accessibilityAddTraits(isTappable ? .isButton : [])
    }
}
