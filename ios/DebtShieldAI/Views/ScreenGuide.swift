import SwiftUI

/// The app's one shared "you're never lost" system.
///
/// Every main screen carries the same two things, built from the pieces here so
/// they look and behave identically everywhere:
///
/// - a `?` **help button** in the toolbar that opens a short, plain-language
///   `ScreenGuide` — *what this screen is* in one line, then numbered steps that
///   point at the exact controls — always available, so anyone stuck on any
///   screen is one tap from an answer;
/// - a `OneTimeHint` banner that appears the first time you land somewhere new
///   and tells you the single next thing to do, then dismisses for good.
///
/// Keeping this in one file means the voice, spacing, and icons stay consistent,
/// and a copy fix lands everywhere at once.

// MARK: - Guide model

/// One numbered "how to use it" step: an icon and a plain sentence.
struct GuideStep: Identifiable {
    let id = UUID()
    let symbol: String
    let text: String
}

/// The content of a screen's help card. Written in the reader's words, not the
/// system's — what they see and tap, never how it's built.
struct ScreenGuide {
    /// The screen's name, e.g. "Your month".
    let title: String
    /// One line: what this screen is for.
    let tagline: String
    /// The handful of things you can do here, in order.
    let steps: [GuideStep]
    /// A calm closing reassurance (privacy, data source, or "not advice").
    let footnote: String
}

// MARK: - Help button (toolbar)

/// The `?` toolbar control. Same glyph, same behaviour on every screen.
struct HelpButton: View {
    let guide: ScreenGuide
    @State private var showing = false

    var body: some View {
        Button {
            showing = true
        } label: {
            Image(systemName: "questionmark.circle")
        }
        .accessibilityLabel("How this screen works")
        .accessibilityHint("Opens a short guide to this screen")
        .sheet(isPresented: $showing) {
            NavigationStack { HelpSheetView(guide: guide) }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Help sheet

/// The card the `?` opens: title, one-line purpose, numbered steps, reassurance.
struct HelpSheetView: View {
    let guide: ScreenGuide
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                VStack(alignment: .leading, spacing: Theme.Spacing.tight) {
                    Text(guide.title)
                        .font(Theme.Typography.title)
                        .accessibilityAddTraits(.isHeader)
                    Text(guide.tagline)
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.comfortable) {
                    ForEach(Array(guide.steps.enumerated()), id: \.element.id) { index, step in
                        HStack(alignment: .top, spacing: Theme.Spacing.regular) {
                            AppIconBadge(systemImage: step.symbol, size: 34)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Step \(index + 1)")
                                    .font(.caption2.weight(.semibold))
                                    .tracking(0.4)
                                    .foregroundStyle(Theme.brand)
                                Text(step.text)
                                    .font(Theme.Typography.subheadline)
                                    .foregroundStyle(.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.top, 1)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Step \(index + 1). \(step.text)")
                    }
                }

                HStack(alignment: .top, spacing: Theme.Spacing.tight) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(Theme.statusColor(.okay))
                        .accessibilityHidden(true)
                    Text(guide.footnote)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(Theme.Spacing.comfortable)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.statusFill(.okay), in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
                .accessibilityElement(children: .combine)
            }
            .padding(Theme.Spacing.comfortable)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.screenGradient)
        .navigationTitle("How this works")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }
}

// MARK: - One-time hint banner

/// A soft, dismissable banner that shows once per person, keyed by `storageKey`,
/// then never again. Used to point at the one thing to do the first time you land
/// on a screen. Reused across screens so every hint looks and behaves the same.
struct OneTimeHint: View {
    var systemImage: String = "hand.point.up.left.fill"
    let text: String
    @AppStorage private var seen: Bool

    init(_ storageKey: String, systemImage: String = "hand.point.up.left.fill", text: String) {
        self.systemImage = systemImage
        self.text = text
        _seen = AppStorage(wrappedValue: false, storageKey)
    }

    var body: some View {
        if !seen {
            HStack(spacing: Theme.Spacing.tight) {
                Image(systemName: systemImage)
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Theme.brand)
                    .accessibilityHidden(true)
                Text(text)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Button { withAnimation { seen = true } } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Theme.secondaryText.opacity(0.5))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss hint")
            }
            .padding(Theme.Spacing.regular)
            .background {
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .fill(Theme.brand.opacity(0.08))
            }
            .accessibilityElement(children: .combine)
        }
    }
}

#if DEBUG
#Preview("Help sheet") {
    NavigationStack {
        HelpSheetView(guide: ScreenGuide(
            title: "Where you'd have room",
            tagline: "See where your money would stretch furthest across the U.S. — for perspective, never a nudge to move.",
            steps: [
                GuideStep(symbol: "list.number", text: "The list ranks places by how much you'd have left over living there."),
                GuideStep(symbol: "briefcase.fill", text: "Tap “See where your job pays best” to re-rank by a job's local pay — 300+ jobs."),
                GuideStep(symbol: "bookmark.fill", text: "Tap any place to see the full breakdown, or save it to compare later.")
            ],
            footnote: "Rents and incomes come from public U.S. Census data. Nothing you enter leaves your phone."))
    }
}
#endif
