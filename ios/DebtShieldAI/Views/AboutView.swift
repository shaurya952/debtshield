import SwiftUI

/// The About tab: what the app is, how it works, and the terms.
struct AboutView: View {
    let store: MoneyPlanStore
    /// Lets the reader see the introduction again.
    var replayOnboarding: () -> Void

    @AppStorage("debtshield.appLockEnabled") private var appLockEnabled = false
    @State private var showDeleteConfirm = false

    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "Version \(short) (\(build))"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                headerCard
                referenceCard
                dataSecurityCard
                legalCard
                aboutCard
                versionFooter
            }
            .padding(Theme.Spacing.comfortable)
        }
        .background(Theme.screenGradient)
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Header

    private var headerCard: some View {
        Card {
            HStack(spacing: Theme.Spacing.regular) {
                BrandMark(size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text("DebtShield")
                        .font(.title3.weight(.bold))
                    Text("See where your money stands each month")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            .accessibilityElement(children: .combine)

            Text("Your numbers stay on your phone. No account, no tracking, nothing sent anywhere.")
                .font(Theme.Typography.footnote)
                .foregroundStyle(Theme.secondaryText)
        }
    }

    // MARK: - Sections

    private var referenceCard: some View {
        Card {
            SectionHeader(title: "Understand the app")

            NavigationLink {
                HowItWorksView()
            } label: {
                DetailNavigationRow(
                    title: "How it works",
                    subtitle: "The safe line, and where the comparison numbers come from",
                    systemImage: "chart.bar.doc.horizontal"
                )
            }
            .buttonStyle(.plain)

            Divider()

            Button {
                replayOnboarding()
            } label: {
                DetailNavigationRow(
                    title: "Show the welcome screen again",
                    subtitle: "The screen shown when the app first opens",
                    systemImage: "arrow.counterclockwise"
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Your data & security

    private var dataSecurityCard: some View {
        Card {
            SectionHeader(title: "Your data & security")

            Toggle(isOn: $appLockEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Require Face ID to open")
                        .font(Theme.Typography.body.weight(.semibold))
                    Text("Lock the app with Face ID, Touch ID, or your device passcode.")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .tint(Theme.brand)
            .frame(minHeight: Theme.minimumTapTarget)
            .accessibilityHint("Requires biometric or passcode unlock each time the app opens")

            Divider()

            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                HStack(spacing: Theme.Spacing.regular) {
                    AppIconBadge(systemImage: "trash.fill", tint: Theme.statusColor(.over), size: 34)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Delete my numbers")
                            .font(Theme.Typography.body.weight(.semibold))
                            .foregroundStyle(Theme.statusColor(.over))
                        Text("Erases the income, essentials, saved months, and area you entered — from this phone. The app and its built-in comparison data stay.")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: Theme.minimumTapTarget)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .confirmationDialog("Delete your numbers?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete my numbers", role: .destructive) { store.clear() }
            Button("Keep them", role: .cancel) {}
        } message: {
            Text("This removes the income, essentials, saved months, and area you entered on this phone. It can't be undone. The app's built-in comparison data (U.S. Census, EIA, BLS) is not affected.")
        }
    }

    private var legalCard: some View {
        Card {
            SectionHeader(title: "Terms and privacy")

            NavigationLink {
                DisclaimerView()
            } label: {
                DetailNavigationRow(
                    title: "The fine print",
                    subtitle: "A clear picture of your month — not financial or legal advice",
                    systemImage: "exclamationmark.circle"
                )
            }
            .buttonStyle(.plain)

            Divider()

            NavigationLink {
                PrivacyView()
            } label: {
                DetailNavigationRow(
                    title: "Privacy",
                    subtitle: "Your numbers never leave this device",
                    systemImage: "lock.shield"
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var aboutCard: some View {
        Card {
            SectionHeader(title: "About DebtShield")
            Text("DebtShield is a calm, private way to see your money. You enter what comes in and what goes out, and it shows you where the month stands — in plain dollars, without a score or a lecture. The goal is simple: to help you stay out of debt, or find your footing if you're already in it.")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            Text("The comparison numbers come from public data — the U.S. Census Bureau, the EIA, and the BLS. Everything runs on your phone.")
                .font(Theme.Typography.footnote)
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var versionFooter: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(version)
                .font(Theme.Typography.footnote)
                .foregroundStyle(Theme.secondaryText)
            Text("Comparison data: U.S. Census Bureau (rent), EIA (energy, 2024), BLS (food, 2024). Public domain.")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
#Preview {
    NavigationStack { AboutView(store: .preview(.sampleTight), replayOnboarding: {}) }
}
#endif
