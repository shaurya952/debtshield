import SwiftUI

/// The About tab: what the app is, how it works, and the terms.
struct AboutView: View {
    let store: MoneyPlanStore
    /// Lets the reader see the introduction again.
    var replayOnboarding: () -> Void

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
                trustCenterLink
                referenceCard
                MonthlyCheckInCard()
                DataSecurityCard(store: store)
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
        VStack(spacing: Theme.Spacing.regular) {
            BrandMark(size: 48)
                .padding(14)
                .background(Circle().fill(.white))
                .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)

            VStack(spacing: 4) {
                Text("DebtShield")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.white)
                Text("See where your money stands each month")
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Label("Private · on-device · no tracking", systemImage: "lock.fill")
                .font(Theme.Typography.footnote.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(.white.opacity(0.18)))
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.comfortable)
        .padding(.vertical, Theme.Spacing.regular)
        .background {
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .fill(Theme.brandGradient)
                .shadow(color: Theme.heroShadow, radius: 14, x: 0, y: 8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("DebtShield. See where your money stands each month. Private, on-device, no tracking.")
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

            NavigationLink {
                MethodologyView()
            } label: {
                DetailNavigationRow(
                    title: "Places: methods & sources",
                    subtitle: "The data, the ranking, and what it can't tell you",
                    systemImage: "map.circle"
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

            Divider()

            NavigationLink {
                FeedbackView(store: store)
            } label: {
                DetailNavigationRow(
                    title: "Send feedback",
                    subtitle: "Report a bug or a confusing result — privately",
                    systemImage: "bubble.left.and.text.bubble.right"
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Trust Center entry

    private var trustCenterLink: some View {
        NavigationLink {
            TrustCenterView(store: store)
        } label: {
            ActionRowLabel(
                systemImage: "checkmark.shield.fill",
                title: "Trust Center",
                subtitle: "What we do and don't do, your privacy, our methods and sources, and free help"
            )
        }
        .buttonStyle(PressableCardStyle())
        .accessibilityHint("Opens the Trust Center")
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
