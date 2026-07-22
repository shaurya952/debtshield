import SwiftUI

/// The fifth and final tab: what the app is, and every explanatory screen.
struct AboutView: View {
    let dataset: Dataset
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
                referenceCard
                legalCard
                aboutProjectCard
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
                    Text("DebtShield AI")
                        .font(.title3.weight(.bold))
                    Text("Financial pressure across U.S. counties")
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            .accessibilityElement(children: .combine)

            // `sourceDescription` already carries a county count, so it is not
            // repeated here — otherwise the line reads "3,144 counties · 51
            // states · … · 3,144 counties".
            Text("\(dataset.counties.count.formatted(.number)) counties · \(dataset.states.count) states")
                .font(.footnote.weight(.medium))
            Text("U.S. Census Bureau, American Community Survey 5-Year estimates")
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
        }
    }

    // MARK: - Sections

    private var referenceCard: some View {
        Card {
            SectionHeader(title: "Understand the app")

            NavigationLink {
                MethodologyView(dataset: dataset)
            } label: {
                DetailNavigationRow(
                    title: "Methodology",
                    subtitle: "How the Financial Distress Index is calculated, and what it cannot tell you",
                    systemImage: "function"
                )
            }
            .buttonStyle(.plain)

            Divider()

            NavigationLink {
                GlossaryView()
            } label: {
                DetailNavigationRow(
                    title: "Glossary",
                    subtitle: "Plain-English definitions for every term used in the app",
                    systemImage: "character.book.closed"
                )
            }
            .buttonStyle(.plain)

            Divider()

            Button {
                replayOnboarding()
            } label: {
                DetailNavigationRow(
                    title: "Show the introduction again",
                    subtitle: "The welcome screen shown when the app first opens",
                    systemImage: "arrow.counterclockwise"
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var legalCard: some View {
        Card {
            SectionHeader(title: "Terms and privacy")

            NavigationLink {
                DisclaimerView()
            } label: {
                DetailNavigationRow(
                    title: "Disclaimer",
                    subtitle: "Educational use only — not financial, legal, or benefits advice",
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
                    subtitle: "No account, no tracking, nothing sent off your device",
                    systemImage: "lock.shield"
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var aboutProjectCard: some View {
        Card {
            SectionHeader(title: "About this project")
            Text("DebtShield AI began as a research project analysing which U.S. counties face the most financial pressure and why. This app rebuilds that work natively, with the scoring reimplemented in Swift so every figure can be traced back to the public statistic it came from.")
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
            Text("It is a research prototype. It is deliberately explicit about what it does not know: two counties cannot be scored, three risk drivers have no data source, and the machine-learning models from the original research are reported honestly rather than presented as powering the app.")
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
        }
    }

    private var versionFooter: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(version)
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
            Text("Data: U.S. Census Bureau, American Community Survey 5-Year estimates. Public domain.")
                .font(.caption)
                .foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
