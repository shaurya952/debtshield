import SwiftUI

/// Searchable county selector.
///
/// Presented as a sheet so choosing a county never loses the profile behind it.
struct CountyPickerView: View {
    let dataset: Dataset
    let searchIndex: CountySearchIndex
    let favorites: FavoritesManager
    var onSelect: (ScoredCounty) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var riskFilter: RiskLevel?
    @State private var outcome = CountySearchIndex.Outcome.empty

    private var results: [ScoredCounty] { outcome.counties }
    private var totalMatches: Int { outcome.totalMatches }

    /// Identity for `.task(id:)` — recomputes only when the query or the filter
    /// actually changes, instead of on every body pass.
    private struct Request: Equatable {
        var query: String
        var risk: RiskLevel?
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    riskFilterPicker
                        .listRowInsets(EdgeInsets(top: Theme.Spacing.tight, leading: 0,
                                                  bottom: Theme.Spacing.tight, trailing: 0))
                        .listRowBackground(Color.clear)
                }

                // Saved and recent counties are the fastest way back to
                // somewhere you have already been, so they sit above the full
                // list until the user starts typing or filtering.
                if isBrowsing {
                    quickAccessSection(
                        title: "Saved",
                        systemImage: "star.fill",
                        counties: favorites.favorites(in: dataset)
                    )
                    quickAccessSection(
                        title: "Recently viewed",
                        systemImage: "clock",
                        counties: favorites.recents(in: dataset)
                    )
                }

                if results.isEmpty {
                    Section { noResults }
                } else {
                    Section {
                        ForEach(results) { county in
                            Button {
                                onSelect(county)
                                dismiss()
                            } label: {
                                CountyResultRow(county: county)
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        Text(resultsSummary)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Choose a county")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "County or state"
            )
            .autocorrectionDisabled()
            .textInputAutocapitalization(.words)
            .task(id: Request(query: query, risk: riskFilter)) {
                outcome = searchIndex.results(for: query, riskFilter: riskFilter)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    /// True when the user has neither typed nor filtered — i.e. is browsing
    /// rather than searching.
    private var isBrowsing: Bool {
        query.trimmingCharacters(in: .whitespaces).isEmpty && riskFilter == nil
    }

    @ViewBuilder
    private func quickAccessSection(
        title: String,
        systemImage: String,
        counties: [ScoredCounty]
    ) -> some View {
        if !counties.isEmpty {
            Section {
                ForEach(counties) { county in
                    Button {
                        onSelect(county)
                        dismiss()
                    } label: {
                        CountyResultRow(county: county)
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Label(title, systemImage: systemImage)
            }
        }
    }

    // MARK: - Filter

    /// A standard segmented control: VoiceOver announces it as a picker with
    /// the selected option, and it needs no custom accessibility work.
    private var riskFilterPicker: some View {
        Picker("Filter by risk level", selection: $riskFilter) {
            Text("All").tag(RiskLevel?.none)
            ForEach(RiskLevel.allCases) { level in
                Text(level.label).tag(RiskLevel?.some(level))
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Filter by risk level")
        .accessibilityHint("Limits the list to counties at the chosen risk level")
    }

    // MARK: - Results

    private var resultsSummary: String {
        let shown = results.count
        if shown < totalMatches {
            return "Showing \(shown) of \(totalMatches.formatted(.number)) matches"
        }
        return "\(totalMatches.formatted(.number)) \(totalMatches == 1 ? "county" : "counties")"
    }

    /// Plain-language empty state that says what to try next, rather than an
    /// empty list or a bare "no results".
    private var noResults: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.tight) {
            Text(emptyStateTitle)
                .font(.headline)
            Text("Try a county name like \"Cook\", a state like \"Illinois\", or both together. Partial spelling works.")
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
            if riskFilter != nil {
                Button("Clear the risk filter") { riskFilter = nil }
                    .font(.subheadline.weight(.semibold))
                    .frame(minHeight: Theme.minimumTapTarget)
            }
        }
        .padding(.vertical, Theme.Spacing.tight)
        .accessibilityElement(children: .contain)
    }

    private var emptyStateTitle: String {
        if query.isEmpty, let riskFilter {
            return "No counties are currently \(riskFilter.label.lowercased()) risk."
        }
        return "No counties match \"\(query)\"."
    }
}

// MARK: - Row

/// One search result. The whole row is a single 44pt-plus tap target and a
/// single VoiceOver element.
struct CountyResultRow: View {
    let county: ScoredCounty

    var body: some View {
        HStack(spacing: Theme.Spacing.regular) {
            VStack(alignment: .leading, spacing: 2) {
                Text(county.county)
                    .font(.body.weight(.medium))
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(.primary)
                Text(county.state)
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)
            }

            Spacer(minLength: Theme.Spacing.tight)

            if let index = county.index, let riskLevel = county.riskLevel {
                Text(index.scoreText)
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Theme.secondaryText)
                RiskBadge(level: riskLevel, compact: true)
            } else {
                UnscoredBadge()
            }
        }
        .padding(.vertical, Theme.Spacing.tight)
        .frame(minHeight: Theme.minimumTapTarget)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(county.accessibilitySummary)
        .accessibilityHint("Opens this county's profile")
        .accessibilityAddTraits(.isButton)
    }
}
