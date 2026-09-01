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
                TourPreview(step: tourIndex, tint: step.tint)
                    .frame(height: 268)
                    .frame(maxWidth: .infinity)
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
            .transition(reduceMotion ? .identity : .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)))

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

/// A small, polished mock of the real screen for each onboarding step — so the
/// tour shows the app, not just an icon. This is where "half nice" becomes a
/// proper product tour: real-looking cards, the app's own colours and shapes.
private struct TourPreview: View {
    let step: Int
    let tint: Color
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Theme.brandGradient)
                .opacity(0.14)
            card
                .padding(22)
                .scaleEffect(appeared || reduceMotion ? 1 : 0.94)
                .opacity(appeared || reduceMotion ? 1 : 0)
        }
        .onAppear {
            guard !reduceMotion else { appeared = true; return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { appeared = true }
        }
    }

    @ViewBuilder private var card: some View {
        switch step {
        case 0: homeCard
        case 1: placesCard
        case 2: jobCard
        case 3: movePlanCard
        default: privacyCard
        }
    }

    private func shell<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) { content() }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Theme.cardBackground))
            .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 10)
    }

    // Step 0 — the month at a glance.
    private var homeCard: some View {
        shell {
            Text("✓ On track").font(.caption.weight(.bold)).foregroundStyle(Theme.statusColor(.okay))
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Capsule().fill(Theme.statusColor(.okay).opacity(0.15)))
            Text("$2,450").font(.system(size: 44, weight: .heavy, design: .rounded))
            Text("left this month").font(.subheadline).foregroundStyle(Theme.secondaryText)
            GeometryReader { g in
                HStack(spacing: 3) {
                    seg(Theme.essentialColor(.housing), 0.42, g.size.width)
                    seg(Theme.essentialColor(.food), 0.14, g.size.width)
                    seg(Theme.essentialColor(.energy), 0.10, g.size.width)
                    seg(Theme.statusColor(.okay).opacity(0.35), 0.34, g.size.width)
                }
            }
            .frame(height: 20)
        }
    }
    private func seg(_ c: Color, _ frac: CGFloat, _ total: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 5, style: .continuous).fill(c)
            .frame(width: max(2, total * frac - 3))
    }

    // Step 1 — the metro ranking.
    private var placesCard: some View {
        shell {
            Text("Best metro areas").font(.headline)
            rankRow("1", "Austin, TX", "+$3,350")
            rankRow("2", "Raleigh, NC", "+$3,200")
            rankRow("3", "Boise, ID", "+$3,050")
        }
    }
    private func rankRow(_ n: String, _ name: String, _ amt: String) -> some View {
        HStack(spacing: 12) {
            Text(n).font(.callout.weight(.semibold).monospacedDigit()).foregroundStyle(Theme.secondaryText).frame(width: 18)
            Text(name).font(.subheadline.weight(.semibold))
            Spacer()
            Text(amt).font(.subheadline.weight(.bold)).foregroundStyle(Theme.statusColor(.okay))
        }
        .padding(.vertical, 8).padding(.horizontal, 12)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.screenBackground))
    }

    // Step 2 — rank by a job's local pay.
    private var jobCard: some View {
        shell {
            HStack(spacing: 8) {
                Image(systemName: "briefcase.fill").foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(Theme.brand))
                VStack(alignment: .leading, spacing: 0) {
                    Text("Ranking by").font(.caption2).foregroundStyle(Theme.secondaryText)
                    Text("Registered Nurse").font(.subheadline.weight(.bold))
                }
                Spacer()
                Text("116 jobs").font(.caption).foregroundStyle(Theme.brand)
            }
            rankRow("1", "California", "$8,700/mo")
            rankRow("2", "Oregon", "$7,200/mo")
        }
    }

    // Step 3 — the move plan.
    private var movePlanCard: some View {
        shell {
            HStack(spacing: 8) {
                Image(systemName: "flag.checkered").foregroundStyle(Theme.brand)
                Text("Move goal · Austin, TX").font(.subheadline.weight(.bold))
            }
            ProgressView(value: 0.6).tint(Theme.brand)
            HStack {
                Text("$2,400 of $4,000 fund").font(.caption).foregroundStyle(Theme.secondaryText)
                Spacer(); Text("60%").font(.caption.weight(.bold)).foregroundStyle(Theme.brand)
            }
            HStack(spacing: 8) {
                ForEach(["+$100", "+$500"], id: \.self) { t in
                    Text(t).font(.caption.weight(.semibold)).foregroundStyle(Theme.brand)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Capsule().stroke(Theme.brand.opacity(0.4)))
                }
            }
        }
    }

    // Step 4 — private by design.
    private var privacyCard: some View {
        shell {
            Image(systemName: "lock.fill").font(.system(size: 30, weight: .bold)).foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.statusColor(.okay)))
            Text("On this iPhone only").font(.headline)
            Text("No account · no server · nothing uploaded").font(.caption).foregroundStyle(Theme.secondaryText)
            HStack(spacing: 6) {
                ForEach(["Census", "EIA", "BLS"], id: \.self) { s in
                    Text(s).font(.caption2.weight(.semibold)).foregroundStyle(Theme.secondaryText)
                        .padding(.horizontal, 9).padding(.vertical, 4)
                        .background(Capsule().fill(Theme.screenBackground))
                }
            }
        }
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
