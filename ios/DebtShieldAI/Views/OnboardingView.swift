import SwiftUI

/// The first screen a new person sees.
///
/// Calm and warm on purpose: one promise, one button. Someone anxious about
/// money should feel met, not quizzed or warned. It is a single scrolling screen
/// rather than a swipeable carousel — paged onboarding hides content behind a
/// swipe, which is awkward with VoiceOver, invisible to anyone who doesn't think
/// to swipe, and breaks at large Dynamic Type sizes.
///
/// The one non-advice line sits above the button so it is seen before anyone
/// continues, but it is a quiet reassurance rather than a wall of warning.
struct OnboardingView: View {
    /// Called when the reader continues. The caller records that onboarding has
    /// been seen, so this appears on first launch only.
    var onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.section) {
                Spacer(minLength: Theme.Spacing.section)

                BrandMark(size: 84)
                    .padding(30)
                    .background {
                        Circle()
                            .fill(Theme.iconWell(Theme.brand))
                            .overlay(Circle().strokeBorder(Theme.brand.opacity(0.10), lineWidth: 1))
                    }
                    .accessibilityHidden(true)

                VStack(spacing: Theme.Spacing.regular) {
                    Text("DebtShield")
                        .font(.largeTitle.weight(.bold))
                        .accessibilityAddTraits(.isHeader)

                    // The one promise.
                    Text("Know where your money stands this month.")
                        .font(Theme.Typography.title)
                        .multilineTextAlignment(.center)

                    Text("No score, no judgment — just your real numbers, in plain dollars, kept on your phone.")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)

                Spacer(minLength: Theme.Spacing.section)

                VStack(spacing: Theme.Spacing.comfortable) {
                    Text("DebtShield helps you see your own money. It isn't financial or legal advice.")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.secondaryText)
                        .multilineTextAlignment(.center)

                    Button {
                        onContinue()
                    } label: {
                        Text("Get started")
                            .font(Theme.Typography.body.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: Theme.minimumTapTarget)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityHint("Opens the app")
                }
            }
            .padding(Theme.Spacing.section)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 640)
        }
        .background(Theme.screenGradient)
    }
}

#if DEBUG
#Preview {
    OnboardingView(onContinue: {})
}
#endif
