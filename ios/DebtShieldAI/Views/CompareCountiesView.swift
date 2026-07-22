import SwiftUI

/// Phase 3 Compare Counties.
///
/// The Streamlit version drew one grouped matplotlib bar chart with every
/// metric crammed onto a single axis. On a phone that is unreadable, so this
/// gives each indicator its own card with a labelled bar per county — which
/// also means each card is a self-contained VoiceOver unit.
struct CompareCountiesView: View {
    let dataset: Dataset
    let searchIndex: CountySearchIndex
    let comparison: ComparisonStore
    let favorites: FavoritesManager

    @State private var isPickerPresented = false

    private var counties: [ScoredCounty] { comparison.counties(in: dataset) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                selectedCountiesCard

                if comparison.hasEnoughToCompare {
                    overviewCard
                    ForEach(ComparisonMetric.allCases) { metric in
                        metricCard(metric)
                    }
                } else {
                    guidanceCard
                }

                EducationalDisclaimer()
            }
            .padding(Theme.Spacing.comfortable)
        }
        .background(Theme.screenGradient)
        .navigationTitle("Compare")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPickerPresented = true
                } label: {
                    Label("Add county", systemImage: "plus")
                }
                .disabled(!comparison.canAddMore)
                .accessibilityHint(
                    comparison.canAddMore
                        ? "Adds a county to the comparison"
                        : "Remove a county before adding another"
                )
            }
        }
        .sheet(isPresented: $isPickerPresented) {
            CountyPickerView(
                dataset: dataset,
                searchIndex: searchIndex,
                favorites: favorites
            ) { county in
                comparison.add(county)
            }
        }
    }

    // MARK: - Selected counties

    private var selectedCountiesCard: some View {
        Card {
            SectionHeader(
                title: "Comparing \(counties.count) of \(ComparisonStore.maxCounties)",
                subtitle: "Choose two to four counties"
            )

            if counties.isEmpty {
                Text("No counties selected yet.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
            } else {
                ForEach(Array(counties.enumerated()), id: \.element.id) { position, county in
                    if position > 0 { Divider() }
                    HStack(spacing: Theme.Spacing.regular) {
                        Circle()
                            .fill(Theme.comparisonColor(at: position))
                            .frame(width: 12, height: 12)
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(county.county)
                                .font(.body.weight(.medium))
                            Text(county.state)
                                .font(.footnote)
                                .foregroundStyle(Theme.secondaryText)
                        }

                        Spacer(minLength: Theme.Spacing.tight)

                        Button {
                            comparison.remove(county)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(Theme.secondaryText)
                                .frame(width: Theme.minimumTapTarget, height: Theme.minimumTapTarget)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Remove \(county.displayName)")
                        .accessibilityHint("Takes this county out of the comparison")
                    }
                    .frame(minHeight: Theme.minimumTapTarget)
                }
            }

            HStack(spacing: Theme.Spacing.regular) {
                Button {
                    isPickerPresented = true
                } label: {
                    Label("Add county", systemImage: "plus")
                        .frame(maxWidth: .infinity, minHeight: Theme.minimumTapTarget)
                }
                .buttonStyle(.bordered)
                .disabled(!comparison.canAddMore)

                if !counties.isEmpty {
                    Button(role: .destructive) {
                        comparison.removeAll()
                    } label: {
                        Text("Clear")
                            .frame(minHeight: Theme.minimumTapTarget)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityHint("Removes every county from the comparison")
                }
            }
        }
    }

    // MARK: - Guidance / quick add

    private var guidanceCard: some View {
        let suggestions = quickAddSuggestions

        return Card {
            SectionHeader(
                title: "Add one more county",
                subtitle: "A comparison needs at least two"
            )

            if suggestions.isEmpty {
                Text("Tap Add county to search all \(dataset.counties.count.formatted(.number)) U.S. counties.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
            } else {
                Text("Quick add")
                    .font(.subheadline.weight(.semibold))
                ForEach(Array(suggestions.enumerated()), id: \.element.id) { position, county in
                    if position > 0 { Divider() }
                    Button {
                        comparison.add(county)
                    } label: {
                        CountyResultRow(county: county)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    /// Favourites first, then recently viewed, then the highest-scoring
    /// counties — whatever the user is most likely to want, without ever
    /// suggesting a county already in the comparison.
    private var quickAddSuggestions: [ScoredCounty] {
        var seen = Set(comparison.countyIDs)
        var result: [ScoredCounty] = []
        for county in favorites.favorites(in: dataset)
            + favorites.recents(in: dataset)
            + dataset.highestRisk {
            guard !seen.contains(county.id) else { continue }
            seen.insert(county.id)
            result.append(county)
            if result.count == 4 { break }
        }
        return result
    }

    // MARK: - Overview

    private var overviewCard: some View {
        Card {
            SectionHeader(
                title: "Overall risk",
                subtitle: "Financial Distress Index and risk level"
            )
            ForEach(Array(counties.enumerated()), id: \.element.id) { position, county in
                if position > 0 { Divider() }
                VStack(alignment: .leading, spacing: Theme.Spacing.tight) {
                    Text(county.displayName)
                        .font(.subheadline.weight(.semibold))
                    HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.tight) {
                        if let index = county.index, let riskLevel = county.riskLevel {
                            Text(index.scoreText)
                                .font(.title2.weight(.bold).monospacedDigit())
                            Text("of 100")
                                .font(.caption)
                                .foregroundStyle(Theme.secondaryText)
                            Spacer(minLength: Theme.Spacing.tight)
                            RiskBadge(level: riskLevel, compact: true)
                        } else {
                            Spacer(minLength: 0)
                            UnscoredBadge()
                        }
                    }
                    if let rank = dataset.rank(of: county) {
                        Text("Ranked \(rank.formatted(.number)) of \(dataset.scoredCounties.count.formatted(.number))")
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryText)
                    } else {
                        Text("The Census does not publish enough data to score this county.")
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
                .padding(.vertical, Theme.Spacing.tight)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(county.displayName)
                .accessibilityValue(overviewAccessibilityValue(for: county))
            }
        }
    }

    private func overviewAccessibilityValue(for county: ScoredCounty) -> String {
        guard let index = county.index,
              let riskLevel = county.riskLevel,
              let rank = dataset.rank(of: county)
        else { return "No score. The Census does not publish enough data for this county." }

        return "\(riskLevel.label) risk. Index \(index.scoreText) of 100. "
            + "Ranked \(rank) of \(dataset.scoredCounties.count)."
    }

    // MARK: - Metric cards

    private func metricCard(_ metric: ComparisonMetric) -> some View {
        let values = counties.map { metric.value(for: $0) }
        let available = values.compactMap { $0 }
        let scaleMax = metric.fixedScaleMax ?? max(available.max() ?? 1, 0.0001)

        return Card {
            SectionHeader(title: metric.title, subtitle: metric.explanation)

            if available.isEmpty {
                // Every county is missing this indicator — say so once, rather
                // than repeating "Not reported" on each row.
                Label(metric.missingDataNote, systemImage: "questionmark.circle")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)
            } else {
                ForEach(Array(counties.enumerated()), id: \.element.id) { position, county in
                    ComparisonRow(
                        county: county,
                        metric: metric,
                        value: metric.value(for: county),
                        scaleMax: scaleMax,
                        color: Theme.comparisonColor(at: position)
                    )
                }

                if let summary = extremesSummary(metric, values: values) {
                    Text(summary)
                        .font(.footnote)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
        }
    }

    /// "Highest: X. Lowest: Y." — the comparison stated in words, so the point
    /// of the card survives without seeing the bars.
    private func extremesSummary(_ metric: ComparisonMetric, values: [Double?]) -> String? {
        let pairs = zip(counties, values).compactMap { county, value in
            value.map { (county: county, value: $0) }
        }
        guard pairs.count >= 2,
              let highest = pairs.max(by: { $0.value < $1.value }),
              let lowest = pairs.min(by: { $0.value < $1.value }),
              highest.county.id != lowest.county.id
        else { return nil }

        return "Highest: \(highest.county.county), \(metric.formatted(highest.value)). "
            + "Lowest: \(lowest.county.county), \(metric.formatted(lowest.value))."
    }
}

// MARK: - Comparison row

/// One county's value for one indicator, with a proportional bar.
struct ComparisonRow: View {
    let county: ScoredCounty
    let metric: ComparisonMetric
    let value: Double?
    let scaleMax: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.tight) {
                Text(county.county)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)
                Spacer(minLength: 4)
                Text(value.map { metric.formatted($0) } ?? "—")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(value == nil ? .secondary : .primary)
            }

            if let value {
                ComparisonBar(fraction: scaleMax > 0 ? value / scaleMax : 0, color: color)
            } else {
                Text(metric.missingDataNote)
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
        .padding(.vertical, Theme.Spacing.tight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(county.displayName)
        .accessibilityValue(
            value.map { "\(metric.title): \(metric.formatted($0))" }
                ?? "\(metric.title): \(metric.missingDataNote)"
        )
    }
}

/// Proportional bar. Decorative — the number is always shown as text beside it,
/// so the bar is hidden from VoiceOver rather than announced as a percentage of
/// something the user cannot see.
struct ComparisonBar: View {
    let fraction: Double
    let color: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(uiColor: .tertiarySystemFill))
                Capsule()
                    .fill(color)
                    .frame(width: max(6, proxy.size.width * min(max(fraction, 0), 1)))
            }
        }
        .frame(height: 10)
        .accessibilityHidden(true)
    }
}
