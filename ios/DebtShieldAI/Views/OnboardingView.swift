import SwiftUI

/// First-run introduction.
///
/// Deliberately a single scrolling screen rather than a swipeable carousel.
/// Paged onboarding hides content behind a horizontal swipe, which is awkward
/// with VoiceOver, invisible to anyone who does not think to swipe, and breaks
/// down at large Dynamic Type sizes. Everything here is reachable by scrolling,
/// and the disclaimer cannot be skipped past without being seen.
struct OnboardingView: View {
    /// Called when the reader continues. The caller records that onboarding has
    /// been seen.
    var onContinue: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                    header
                    points
                    disclaimerCard
                    continueButton
                }
                .padding(Theme.Spacing.comfortable)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.screenGradient)
            .navigationTitle("Welcome")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.tight) {
            BrandMark(size: 72)

            Text("DebtShield AI")
                .font(.largeTitle.weight(.bold))
                .accessibilityAddTraits(.isHeader)

            Text("A way to see which U.S. counties are under the most financial pressure, and what is causing it.")
                .font(.title3)
                .foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var points: some View {
        VStack(spacing: Theme.Spacing.regular) {
            OnboardingPoint(
                systemImage: "number.circle",
                title: "One score, explained",
                message: "Every county gets a Financial Distress Index from 0 to 100. The app always shows what went into it, so you can check the reasoning rather than trust the number."
            )
            OnboardingPoint(
                systemImage: "chart.bar.doc.horizontal",
                title: "See what is driving it",
                message: "Housing pressure and cost of living are scored separately, and compared against every other county in the country."
            )
            OnboardingPoint(
                systemImage: "iphone.and.arrow.forward",
                title: "Everything is on your device",
                message: "The county data ships inside the app. There is no account, no sign-in, and nothing is sent anywhere."
            )
            OnboardingPoint(
                systemImage: "questionmark.circle",
                title: "It says when it does not know",
                message: "Two counties are too small for the Census to publish figures for, and three risk factors have no data source yet. The app tells you rather than filling the gaps with guesses."
            )
        }
    }

    /// The educational-use statement. Given its own card, above the button, so
    /// it is read before anyone continues.
    private var disclaimerCard: some View {
        Card {
            HStack(spacing: Theme.Spacing.tight) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(Theme.riskColor(.medium))
                    .accessibilityHidden(true)
                Text("Please read this first")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
            }

            Text("DebtShield AI is an educational and analytical tool. It is **not** financial, legal, or government-benefit advice, and it does not describe any individual's circumstances.")
                .font(.subheadline)

            Text("It looks at counties as a whole. It cannot tell you anything about your own situation, and it should not be used to make decisions about your money, your housing, or your benefits.")
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
        }
    }

    private var continueButton: some View {
        Button {
            onContinue()
        } label: {
            Text("I understand — get started")
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: Theme.minimumTapTarget)
        }
        .buttonStyle(.borderedProminent)
        .accessibilityHint("Closes this introduction and opens the app")
    }
}

/// One introduction point.
struct OnboardingPoint: View {
    let systemImage: String
    let title: String
    let message: String

    /// At accessibility text sizes the icon column wastes width, so the layout
    /// stacks instead.
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        Card {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: Theme.Spacing.tight) {
                    icon
                    text
                }
            } else {
                HStack(alignment: .top, spacing: Theme.Spacing.regular) {
                    icon
                    text
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var icon: some View {
        Image(systemName: systemImage)
            .font(.title2)
            .foregroundStyle(Theme.brand)
            .frame(width: 32)
            .accessibilityHidden(true)
    }

    private var text: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
