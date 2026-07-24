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

    @AppStorage("debtshield.userName") private var savedName = ""
    @AppStorage("debtshield.userEmail") private var savedEmail = ""

    @State private var page = 0
    @State private var name = ""
    @State private var email = ""
    @FocusState private var focused: Field?

    private enum Field { case name, email }

    var body: some View {
        Group {
            if page == 0 {
                landing
            } else {
                signUp
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
                    Text("DebtShield")
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
                    withAnimation(.easeInOut) { page = 1 }
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
                    withAnimation(.easeInOut) { page = 0 }
                }
                .font(Theme.Typography.subheadline)
                .frame(maxWidth: .infinity)
            }
            .padding(Theme.Spacing.section)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
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
        onContinue()
    }
}

#if DEBUG
#Preview("Landing") {
    OnboardingView(onContinue: {})
}
#endif
