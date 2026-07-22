import SwiftUI

/// Plain-English definitions for every term the app uses.
///
/// Built from the same `ScrollView` + `Card` pattern as the rest of the app
/// rather than a `List`. The list version rendered its section headers and rows
/// through UIKit internals that the accessibility audit reported against
/// without being able to name the element, which made the findings impossible
/// to act on — and it looked different from every other screen.
struct GlossaryView: View {
    @State private var query = ""

    private var matches: [GlossaryTerm] { Glossary.search(query) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                if matches.isEmpty {
                    noResults
                } else {
                    ForEach(GlossaryTerm.Category.allCases) { category in
                        let terms = Glossary.terms(in: category, matching: query)
                        if !terms.isEmpty {
                            Card {
                                SectionHeader(title: category.rawValue)
                                ForEach(Array(terms.enumerated()), id: \.element.id) { index, term in
                                    if index > 0 { Divider() }
                                    GlossaryRow(term: term)
                                }
                            }
                        }
                    }
                }
            }
            .padding(Theme.Spacing.comfortable)
        }
        .background(Theme.screenGradient)
        .searchable(text: $query, prompt: "Find a term")
        .autocorrectionDisabled()
        .navigationTitle("Glossary")
        .navigationBarTitleDisplayMode(.large)
    }

    private var noResults: some View {
        Card {
            Text("Nothing matches \"\(query)\".")
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)
            Text("Try a shorter word, or clear the search to see all \(Glossary.terms.count) terms.")
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

/// One definition. A single VoiceOver element so the term and its meaning are
/// read together rather than as disconnected fragments.
struct GlossaryRow: View {
    let term: GlossaryTerm

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(term.term)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)

            Text(term.definition)
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            if let example = term.example {
                Text(example)
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)
                    .italic()
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, Theme.Spacing.tight)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(term.term)
        .accessibilityValue([term.definition, term.example].compactMap { $0 }.joined(separator: " "))
    }
}
