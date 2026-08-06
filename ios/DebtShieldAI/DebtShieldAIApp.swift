import SwiftUI
import LocalAuthentication

@main
struct DebtShieldAIApp: App {
    @Environment(\.scenePhase) private var scenePhase
    /// Opt-in app lock. Off by default; toggled in About ▸ Your data & security.
    @AppStorage("debtshield.appLockEnabled") private var appLockEnabled = false
    @State private var locked = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Privacy: cover financial content with a neutral branded screen
                // the moment the app becomes inactive, so figures never appear in
                // the iOS app-switcher snapshot.
                .overlay {
                    if scenePhase != .active {
                        PrivacyCover()
                    }
                }
                // Optional biometric lock, shown while the app is in the
                // foreground but not yet unlocked.
                .overlay {
                    if appLockEnabled && locked && scenePhase == .active {
                        LockScreen(onUnlock: authenticate)
                    }
                }
                .onChange(of: scenePhase) { _, phase in
                    switch phase {
                    case .background:
                        if appLockEnabled { locked = true }
                    case .active:
                        if appLockEnabled && locked { authenticate() }
                    default:
                        break
                    }
                }
                .task {
                    // Lock on a cold launch, if enabled.
                    if appLockEnabled {
                        locked = true
                        authenticate()
                    }
                }
        }
    }

    /// Ask for Face ID / Touch ID, falling back to the device passcode. If the
    /// device has no biometrics or passcode set up, we do not lock the user out.
    private func authenticate() {
        let context = LAContext()
        context.localizedFallbackTitle = "Use Passcode"
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            locked = false
            return
        }
        context.evaluatePolicy(.deviceOwnerAuthentication,
                               localizedReason: "Unlock DebtShield to see your numbers") { success, _ in
            Task { @MainActor in
                if success { locked = false }
            }
        }
    }
}

/// The neutral screen shown over the app in the app switcher and during
/// backgrounding, so no financial content is captured in the OS snapshot.
private struct PrivacyCover: View {
    var body: some View {
        ZStack {
            Theme.brandGradient
                .ignoresSafeArea()
            VStack(spacing: Theme.Spacing.comfortable) {
                BrandMark(size: 72)
                Text("DebtShield")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
            }
        }
        .accessibilityHidden(true)
    }
}

/// The lock screen shown when the optional app lock is on and the app hasn't
/// been unlocked yet. Offers a manual retry if the system prompt was dismissed.
private struct LockScreen: View {
    let onUnlock: () -> Void

    var body: some View {
        ZStack {
            Theme.brandGradient
                .ignoresSafeArea()
            VStack(spacing: Theme.Spacing.section) {
                BrandMark(size: 72)
                VStack(spacing: Theme.Spacing.tight) {
                    Text("DebtShield is locked")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                    Text("Your numbers are hidden until you unlock.")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                }
                Button(action: onUnlock) {
                    Label("Unlock", systemImage: "faceid")
                        .font(Theme.Typography.body.weight(.semibold))
                        .padding(.horizontal, Theme.Spacing.section)
                        .frame(minHeight: Theme.minimumTapTarget)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundStyle(Theme.brand)
            }
            .padding(Theme.Spacing.section)
        }
        .accessibilityAddTraits(.isModal)
        .accessibilityLabel("DebtShield is locked. Unlock to continue.")
    }
}
