import SwiftUI

/// Phase 6 Risk Map.
///
/// A state tile grid rather than a pin map — see `StateTile` for why. Every
/// state is a tap target with a full spoken label, and the same information is
/// repeated as a ranked list underneath, so the screen works identically
/// whether or not the grid can be seen.
struct RiskMapView: View {
    let dataset: Dataset
    /// Selecting a county switches to the County tab, matching the dashboard.
    var onSelectCounty: (ScoredCounty) -> Void

    @State private var metric: StateMetric = .averageIndex
    @State private var selectedState: StateRiskSummary?

    private var summaries: [StateRiskSummary] {
        dataset.stateSummaries(orderedBy: metric)
    }

    private var shading: StateShading {
        StateShading(values: summaries.map { metric.value($0) })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                metricPicker
                gridCard
                legendCard
                rankedListCard
                schematicNote
                EducationalDisclaimer()
            }
            .padding(Theme.Spacing.comfortable)
        }
        .background(Theme.screenGradient)
        .navigationTitle("Risk Map")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedState) { summary in
            StateDetailView(
                dataset: dataset,
                summary: summary,
                onSelectCounty: { county in
                    selectedState = nil
                    onSelectCounty(county)
                }
            )
        }
    }

    // MARK: - Metric

    private var metricPicker: some View {
        Card {
            Picker("Shade by", selection: $metric) {
                ForEach(StateMetric.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Shade the map by")

            Text(metric.description)
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
        }
    }

    // MARK: - Grid

    /// Grows with Dynamic Type so the value inside stays legible, never
    /// dropping below the 44pt minimum tap target.
    @ScaledMetric(relativeTo: .caption) private var scaledTile: CGFloat = 44

    private var tileSize: CGFloat { max(Theme.minimumTapTarget, scaledTile) }
    private var tileSpacing: CGFloat { 4 }

    /// Scrolls horizontally on a phone: eleven columns at a 44pt minimum tap
    /// target is wider than a phone screen, and shrinking the tiles to fit
    /// would put them below the minimum.
    private var gridCard: some View {
        let byState = Dictionary(uniqueKeysWithValues: summaries.map { ($0.state, $0) })
        let shading = self.shading

        return Card {
            SectionHeader(
                title: "Every state",
                subtitle: "One square per state, shaded against the other 50"
            )

            ScrollView(.horizontal, showsIndicators: true) {
                VStack(spacing: tileSpacing) {
                    ForEach(0..<StateGrid.rowCount, id: \.self) { row in
                        HStack(spacing: tileSpacing) {
                            ForEach(0..<StateGrid.columnCount, id: \.self) { column in
                                if let tile = StateGrid.tiles.first(where: { $0.row == row && $0.column == column }),
                                   let summary = byState[tile.name] {
                                    Button {
                                        selectedState = summary
                                    } label: {
                                        StateTileView(
                                            tile: tile,
                                            summary: summary,
                                            metric: metric,
                                            band: shading.band(for: metric.value(summary)),
                                            size: tileSize
                                        )
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    Color.clear.frame(width: tileSize, height: tileSize)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            // Presented as a single element, like the charts. The ranked list
            // below is the accessible equivalent and is fully scalable.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("State risk grid")
            .accessibilityValue(gridSummary)
            .accessibilityHint("A visual overview. The ranked list below has the same figures and opens each state.")

            Text("Each square is one state. The ranked list below gives the same figures as text.")
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
        }
    }

    /// Spoken summary of the grid.
    private var gridSummary: String {
        let ordered = summaries
        guard let highest = ordered.first, let lowest = ordered.last else { return "No data" }
        return "\(ordered.count) states shaded by \(metric.title.lowercased()). "
            + "Highest \(highest.state) at \(metric.format(metric.value(highest))). "
            + "Lowest \(lowest.state) at \(metric.format(metric.value(lowest)))."
    }

    // MARK: - Legend

    private var legendCard: some View {
        let shading = self.shading
        let values = summaries.map { metric.value($0) }

        return Card {
            SectionHeader(title: "How to read the shading")

            HStack(spacing: tileSpacing) {
                ForEach(0..<StateShading.bandCount, id: \.self) { band in
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Theme.mapRamp[band])
                        .frame(height: 22)
                        .accessibilityHidden(true)
                }
            }

            HStack {
                Text(metric.format(values.min() ?? 0))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Theme.secondaryText)
                Spacer()
                Text(metric.format(values.max() ?? 0))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Theme.secondaryText)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Range")
            .accessibilityValue("\(metric.format(values.min() ?? 0)) to \(metric.format(values.max() ?? 0))")

            Text("Shades compare states with each other, not against the risk thresholds. Every state's average index sits in the Low band — the darkest square is the highest of the 51, not a high-risk state.")
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)

            Text("Band boundaries: " + shading.thresholds.map { metric.format($0) }.joined(separator: " · "))
                .font(.caption)
                .foregroundStyle(Theme.secondaryText)
        }
    }

    // MARK: - Ranked list

    /// The grid in words. Present for everyone, not a VoiceOver fallback.
    private var rankedListCard: some View {
        Card {
            SectionHeader(
                title: "States ranked",
                subtitle: "Highest \(metric.title.lowercased()) first"
            )
            ForEach(Array(summaries.enumerated()), id: \.element.id) { position, summary in
                if position > 0 { Divider() }
                Button {
                    selectedState = summary
                } label: {
                    StateRow(rank: position + 1, summary: summary, metric: metric)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var schematicNote: some View {
        Card {
            SectionHeader(title: "About this map")
            Text("This is a schematic, not a geographic map. Each state is an equal square in roughly its national position, so small states stay readable and no state's size implies importance.")
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
            Text("County-level mapping needs a coordinate for each of the \(dataset.counties.count.formatted(.number)) counties. This dataset carries FIPS codes but no coordinates, so plotting counties individually would mean placing them somewhere invented.")
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
        }
    }
}

// MARK: - Tile

struct StateTileView: View {
    let tile: StateTile
    let summary: StateRiskSummary
    let metric: StateMetric
    let band: Int
    let size: CGFloat

    /// Scales with the reader's text size rather than sitting at a fixed 9pt.
    @ScaledMetric(relativeTo: .caption2) private var valueFontSize: CGFloat = 9

    var body: some View {
        VStack(spacing: 0) {
            Text(tile.abbreviation)
                .font(.caption2.weight(.bold))
            Text(metric.format(metric.value(summary)))
                .font(.caption2.weight(.medium).monospacedDigit())
        }
        .foregroundStyle(Theme.mapRampForeground[band])
        .frame(width: size, height: size)
        .background(Theme.mapRamp[band], in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        // The value is printed on the tile, so the shade is never the only
        // carrier of meaning.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(summary.accessibilityDescription(metric: metric))
        .accessibilityHint("Opens the county list for this state")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Ranked row

struct StateRow: View {
    let rank: Int
    let summary: StateRiskSummary
    let metric: StateMetric

    var body: some View {
        HStack(spacing: Theme.Spacing.regular) {
            Text("\(rank)")
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(Theme.secondaryText)
                .frame(minWidth: 24, alignment: .trailing)

            VStack(alignment: .leading, spacing: 2) {
                Text(summary.state)
                    .font(.body.weight(.medium))
                Text(elevatedText)
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: Theme.Spacing.tight)

            Text(metric.format(metric.value(summary)))
                .font(.body.weight(.semibold).monospacedDigit())

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.secondaryText)
                .accessibilityHidden(true)
        }
        .padding(.vertical, Theme.Spacing.regular)
        .frame(minHeight: Theme.minimumTapTarget)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rank \(rank). \(summary.accessibilityDescription(metric: metric))")
        .accessibilityHint("Opens the county list for this state")
        .accessibilityAddTraits(.isButton)
    }

    private var elevatedText: String {
        let elevated = summary.mediumCount + summary.highCount
        if elevated == 0 {
            return "\(summary.scoredCount) counties, all low risk"
        }
        return "\(elevated) of \(summary.scoredCount) counties at medium or high risk"
    }
}

// MARK: - State detail

/// Counties within one state, highest risk first.
struct StateDetailView: View {
    let dataset: Dataset
    let summary: StateRiskSummary
    var onSelectCounty: (ScoredCounty) -> Void

    @Environment(\.dismiss) private var dismiss

    private var counties: [ScoredCounty] {
        dataset.counties
            .filter { $0.state == summary.state }
            .sorted { ($0.index ?? -1) > ($1.index ?? -1) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: Theme.Spacing.tight) {
                        Text("Average index \(summary.averageIndex.scoreText)")
                            .font(.subheadline.weight(.semibold))
                        Text(breakdownText)
                            .font(.footnote)
                            .foregroundStyle(Theme.secondaryText)
                    }
                    .padding(.vertical, Theme.Spacing.tight)
                    .accessibilityElement(children: .combine)
                }

                Section("Counties, highest risk first") {
                    ForEach(counties) { county in
                        Button {
                            onSelectCounty(county)
                        } label: {
                            CountyResultRow(county: county)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(summary.state)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var breakdownText: String {
        var parts = ["\(summary.lowCount) low"]
        if summary.mediumCount > 0 { parts.append("\(summary.mediumCount) medium") }
        if summary.highCount > 0 { parts.append("\(summary.highCount) high") }
        if summary.unscoredCount > 0 { parts.append("\(summary.unscoredCount) without enough data") }
        return parts.joined(separator: " · ")
    }
}
