import SwiftUI

/// A calm place picker for "where do you live", used only to compare rent.
///
/// Unlike the county-analysis picker it shows no scores or grades — just the
/// county, the state, and the typical rent there. It reuses the same search
/// index, so partial names and state names work, but speaks the app's personal
/// voice throughout.
struct AreaPickerView: View {
    let searchIndex: CountySearchIndex
    var onSelect: (ScoredCounty) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var outcome = CountySearchIndex.Outcome.empty

    private var results: [ScoredCounty] { outcome.counties }

    var body: some View {
        NavigationStack {
            List {
                if results.isEmpty {
                    Section { noResults }
                } else {
                    Section {
                        ForEach(results) { county in
                            Button {
                                onSelect(county)
                                dismiss()
                            } label: {
                                AreaRow(county: county)
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        Text(query.isEmpty ? "Start typing your county or state" : "\(outcome.totalMatches.formatted(.number)) matches")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Where you live")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "County or state"
            )
            .autocorrectionDisabled()
            .textInputAutocapitalization(.words)
            .task(id: query) {
                outcome = searchIndex.results(for: query)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var noResults: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.tight) {
            Text(query.isEmpty ? "Search for where you live" : "Nothing matches \"\(query)\".")
                .font(Theme.Typography.headline)
            Text("Try your county name, your state, or both — partial spelling is fine.")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.secondaryText)
        }
        .padding(.vertical, Theme.Spacing.tight)
    }
}

/// One place in the picker: county, state, and typical rent — no grade.
struct AreaRow: View {
    let county: ScoredCounty

    var body: some View {
        HStack(spacing: Theme.Spacing.regular) {
            VStack(alignment: .leading, spacing: 2) {
                Text(county.county)
                    .font(Theme.Typography.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(county.state)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
            Spacer(minLength: Theme.Spacing.tight)
            if let rent = county.record.medianGrossRent {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(rent.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                        .font(Theme.Typography.money())
                    Text("typical rent")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
        }
        .padding(.vertical, Theme.Spacing.tight)
        .frame(minHeight: Theme.minimumTapTarget)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityHint("Chooses this as where you live")
        .accessibilityAddTraits(.isButton)
    }

    private var accessibilityText: String {
        var text = "\(county.county), \(county.state)."
        if let rent = county.record.medianGrossRent {
            text += " Typical rent \(rent.formatted(.currency(code: "USD").precision(.fractionLength(0))))."
        }
        return text
    }
}
