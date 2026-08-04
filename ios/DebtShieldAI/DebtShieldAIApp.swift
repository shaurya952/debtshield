import SwiftUI

@main
struct DebtShieldAIApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Privacy: when the app leaves the foreground (e.g. the app
                // switcher), iOS captures a snapshot of the screen. Cover the UI
                // with a neutral branded screen the moment the app becomes
                // inactive, so income, verdicts, and other financial figures
                // never appear in that snapshot. No animation, so the cover is
                // in place before the snapshot is taken.
                .overlay {
                    if scenePhase != .active {
                        PrivacyCover()
                    }
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
