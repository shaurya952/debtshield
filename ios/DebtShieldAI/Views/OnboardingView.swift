import SwiftUI

/// The front door: a warm landing, then a short, private sign-up.
///
/// Two button-driven steps (never a swipe — that stays accessible with VoiceOver
/// and Dynamic Type). The sign-up is an **on-device profile**: name and an
/// optional email, saved only on this phone. There is no password and no server,
/// because the whole promise of the app is that nothing leaves the device — so
/// the sign-up reassures that truthfully rather than pretending to be a cloud
/// account.
struct OnboardingView: View {
    /// Called when the person finishes setting up. The caller records that
    /// onboarding has been seen.
    var onContinue: () -> Void

    init(onContinue: @escaping () -> Void) {
        self.onContinue = onContinue
        _stage = State(initialValue: .landing)
    }

    /// Starts the flow at a given stage. Used by previews (and a DEBUG snapshot
    /// hook) to drop straight into the tour without stepping through the rest.
    init(onContinue: @escaping () -> Void, startAt stage: Stage) {
        self.onContinue = onContinue
        _stage = State(initialValue: stage)
    }

    @AppStorage("debtshield.userName") private var savedName = ""
    @AppStorage("debtshield.userEmail") private var savedEmail = ""

    @State private var stage: Stage
    @State private var tourIndex = 0
    @State private var name = ""
    @State private var email = ""
    @FocusState private var focused: Field?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum Field { case name, email }
    /// The front door has three stages: a warm landing, the on-device sign-up,
    /// then a short, skippable tour of what the app can do. The tour is part of
    /// the same first-run flow so it's seen once (gated by `hasSeenOnboarding`),
    /// and it's replayable later from About.
    enum Stage { case landing, signUp, tour }

    var body: some View {
        Group {
            switch stage {
            case .landing: landing
            case .signUp: signUp
            case .tour: tour
            }
        }
        .background(Theme.screenGradient)
    }

    // MARK: - Landing

    private var landing: some View {
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
                    Text("Headroom")
                        .font(.largeTitle.weight(.bold))
                        .accessibilityAddTraits(.isHeader)
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

                Button {
                    // Pre-fill if they've been here before.
                    name = savedName
                    email = savedEmail
                    withAnimation(.easeInOut) { stage = .signUp }
                } label: {
                    Text("Get started")
                        .font(Theme.Typography.body.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: Theme.minimumTapTarget)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(Theme.Spacing.section)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 640)
        }
    }

    // MARK: - Sign up (on-device)

    private var signUp: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                VStack(alignment: .leading, spacing: Theme.Spacing.comfortable) {
                    BrandLockup(size: 34)
                    Text("Let's set up your space")
                        .font(.largeTitle.weight(.bold))
                        .accessibilityAddTraits(.isHeader)
                    Text("Just a name to make it yours. This is on your phone only.")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: Theme.Spacing.regular) {
                    field(title: "Your name", text: $name, field: .name)
                        .textContentType(.givenName)
                        .submitLabel(.next)
                        .onSubmit { focused = .email }
                    field(title: "Email (optional)", text: $email, field: .email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .onSubmit { finish() }
                }

                privacyCard

                Button {
                    finish()
                } label: {
                    Text("Continue")
                        .font(Theme.Typography.body.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: Theme.minimumTapTarget)
                }
                .buttonStyle(.borderedProminent)
                .disabled(trimmedName.isEmpty)

                Button("Back") {
                    withAnimation(.easeInOut) { stage = .landing }
                }
                .font(Theme.Typography.subheadline)
                .frame(maxWidth: .infinity)
            }
            .padding(Theme.Spacing.section)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Feature tour (shown once, right after sign-up)

    private struct TourStep: Identifiable {
        let id: Int
        let symbol: String
        let tint: Color
        let title: String
        let body: String
    }

    private var tourSteps: [TourStep] {
        [
            TourStep(id: 0, symbol: "house.fill", tint: Theme.brand,
                     title: "Your month, in plain dollars",
                     body: "Start on Home: your income is the bar, your costs fill it up, and whatever's left is your room this month. No score, no judgment — just your real numbers."),
            TourStep(id: 1, symbol: "map.fill", tint: Theme.statusColor(.okay),
                     title: "Where your money goes furthest",
                     body: "Open the Places tab to rank U.S. metro areas by how much you'd have left living there — your own numbers against each place's real rent. Perspective, never a nudge to move."),
            TourStep(id: 2, symbol: "briefcase.fill", tint: Theme.brand,
                     title: "Rank by your job's local pay",
                     body: "The same career pays very differently across the country. On Places, tap \u{201C}See where your job pays furthest\u{201D}, pick from 116 jobs, and the whole list re-ranks by that job's local pay."),
            TourStep(id: 3, symbol: "flag.checkered", tint: Theme.essentialColor(.debt),
                     title: "Plan a move, at your pace",
                     body: "Found somewhere worth it? Make it your move goal and track a moving fund. Carrying debt? \u{201C}Where debt clears soonest\u{201D} shows where your balance could be gone fastest."),
            TourStep(id: 4, symbol: "lock.shield.fill", tint: Theme.statusColor(.okay),
                     title: "Yours, and private",
                     body: "Every number stays on this phone — no account, no server, nothing uploaded. And the \u{201C}Explain\u{201D} tab answers questions about your month from your own figures, never made up.")
        ]
    }

    private var tour: some View {
        let step = tourSteps[tourIndex]
        let isLast = tourIndex == tourSteps.count - 1
        return VStack(spacing: Theme.Spacing.section) {
            HStack {
                Spacer()
                Button("Skip") { onContinue() }
                    .font(Theme.Typography.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.secondaryText)
                    .opacity(isLast ? 0 : 1)
                    .disabled(isLast)
                    .accessibilityHidden(isLast)
            }

            Spacer(minLength: 0)

            VStack(spacing: Theme.Spacing.section) {
                Image(systemName: step.symbol)
                    .font(.system(size: 46, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 108, height: 108)
                    .background(Circle().fill(step.tint))
                    .shadow(color: step.tint.opacity(0.35), radius: 16, x: 0, y: 8)
                    .accessibilityHidden(true)

                VStack(spacing: Theme.Spacing.regular) {
                    Text(step.title)
                        .font(.title.weight(.bold))
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    Text(step.body)
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.secondaryText)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
            }
            .id(step.id)
            .transition(reduceMotion ? .identity : .opacity)

            Spacer(minLength: 0)

            dots

            Button {
                if isLast {
                    onContinue()
                } else {
                    withAnimation(.easeInOut) { tourIndex += 1 }
                }
            } label: {
                Text(isLast ? "Start using Headroom" : "Next")
                    .font(Theme.Typography.body.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: Theme.minimumTapTarget)
            }
            .buttonStyle(.borderedProminent)

            Button("Back") {
                withAnimation(.easeInOut) {
                    if tourIndex == 0 { stage = .signUp } else { tourIndex -= 1 }
                }
            }
            .font(Theme.Typography.subheadline)
            .frame(maxWidth: .infinity)
        }
        .padding(Theme.Spacing.section)
        .frame(maxWidth: 480)
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
    }

    private var dots: some View {
        HStack(spacing: 8) {
            ForEach(tourSteps.indices, id: \.self) { i in
                Capsule()
                    .fill(i == tourIndex ? Theme.brand : Theme.secondaryText.opacity(0.3))
                    .frame(width: i == tourIndex ? 22 : 8, height: 8)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut, value: tourIndex)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(tourIndex + 1) of \(tourSteps.count)")
    }

    private var privacyCard: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.regular) {
            Image(systemName: "lock.shield.fill")
                .foregroundStyle(Theme.statusColor(.okay))
                .accessibilityHidden(true)
            Text("Your name, email, and numbers stay on this phone. There's no account and no server — nothing is ever uploaded or shared.")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Theme.Spacing.comfortable)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.statusFill(.okay), in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func field(title: String, text: Binding<String>, field: Field) -> some View {
        TextField(title, text: text)
            .font(Theme.Typography.body)
            .padding(Theme.Spacing.comfortable)
            .frame(minHeight: Theme.minimumTapTarget)
            .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
            .focused($focused, equals: field)
            .accessibilityLabel(title)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func finish() {
        guard !trimmedName.isEmpty else { focused = .name; return }
        savedName = trimmedName
        savedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        focused = nil
        withAnimation(.easeInOut) { stage = .tour }
    }
}

#if DEBUG
#Preview("Landing") {
    OnboardingView(onContinue: {})
}

#Preview("Feature tour") {
    OnboardingView(onContinue: {}, startAt: .tour)
}
#endif
