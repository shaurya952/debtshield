import SwiftUI

/// The Trust Center — one place that answers "can I trust this, and what happens
/// to my data?" It consolidates the honest scope of the app, a privacy summary,
/// how the numbers are worked out, the data sources, an accessibility statement,
/// free help, and the data controls. Detailed pages (Privacy, How it works, the
/// fine print) are linked rather than duplicated.
struct TrustCenterView: View {
    let store: MoneyPlanStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                intro
                doesCard
                doesntCard
                privacyCard
                methodologyCard
                sourcesCard
                accessibilityCard
                DataSecurityCard(store: store)
                helpCard
                correctionsCard
            }
            .padding(Theme.Spacing.comfortable)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.screenBackground)
        .navigationTitle("Trust Center")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var intro: some View {
        Text("DebtShield only works if you can trust it. Here's exactly what it does, what it never does, how the numbers are worked out, and how your data is handled — in plain terms.")
            .font(Theme.Typography.body)
            .foregroundStyle(Theme.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Does / doesn't

    private var doesCard: some View {
        Card {
            SectionHeader(title: "What DebtShield does")
            ForEach(Self.does, id: \.self) { markRow($0, "checkmark.circle.fill", Theme.statusColor(.okay)) }
        }
    }

    private var doesntCard: some View {
        Card {
            SectionHeader(title: "What it never does")
            ForEach(Self.doesnt, id: \.self) { markRow($0, "xmark.circle.fill", Theme.secondaryText) }
        }
    }

    private static let does = [
        "Shows your month in plain dollars — income, essentials, and what's left",
        "Keeps every number you enter on this device only",
        "Compares your costs to public benchmarks, for perspective",
        "Estimates the odds ahead with a transparent, seeded simulation",
        "Points you to free, reputable help when money is tight"
    ]

    private static let doesnt = [
        "Send your income, rent, debt, verdicts, or odds anywhere",
        "Use a server, an account, ads, or tracking",
        "Connect to your bank or credit",
        "Give individualized financial, investment, legal, or tax advice",
        "Promise to prevent debt, eviction, or bankruptcy",
        "Grade or shame you"
    ]

    private func markRow(_ text: String, _ symbol: String, _ color: Color) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.regular) {
            Image(systemName: symbol)
                .foregroundStyle(color)
                .frame(width: 24)
                .accessibilityHidden(true)
            Text(text)
                .font(Theme.Typography.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Links to detail

    private var privacyCard: some View {
        Card {
            SectionHeader(title: "Your privacy")
            Text("No servers, no network requests, no analytics. What you enter is saved only in the app's own storage on this device, and works fully offline.")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            NavigationLink {
                PrivacyView()
            } label: {
                DetailNavigationRow(title: "Full privacy details",
                                    subtitle: "What's stored, and what the app never touches",
                                    systemImage: "lock.shield")
            }
            .buttonStyle(.plain)
        }
    }

    private var methodologyCard: some View {
        Card {
            SectionHeader(title: "How we work it out")
            Text("The safe line, the verdict, and the year-ahead odds are all computed on your device from the numbers you enter. The simulation is seeded, so the same numbers always give the same result, and every card shows its assumptions.")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            NavigationLink {
                HowItWorksView()
            } label: {
                DetailNavigationRow(title: "How it works",
                                    subtitle: "The safe line and where the comparison numbers come from",
                                    systemImage: "chart.bar.doc.horizontal")
            }
            .buttonStyle(.plain)
            NavigationLink {
                DisclaimerView()
            } label: {
                DetailNavigationRow(title: "Assumptions & limits",
                                    subtitle: "Educational information, not financial or legal advice",
                                    systemImage: "exclamationmark.circle")
            }
            .buttonStyle(.plain)
        }
    }

    private var sourcesCard: some View {
        Card {
            SectionHeader(title: "Where the comparison data comes from")
            sourceRow("Rent & income", "U.S. Census Bureau — American Community Survey, 5-year (2019–2023).")
            sourceRow("Energy", "U.S. Energy Information Administration (EIA), 2024.")
            sourceRow("Food", "U.S. Bureau of Labor Statistics — Consumer Expenditure Survey, 2023.")
            Text("These are broad public averages, bundled inside the app and read-only. They're a reference, never a target you must hit.")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func sourceRow(_ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.regular) {
            Image(systemName: "circle.fill")
                .font(.system(size: 7))
                .foregroundStyle(Theme.brand)
                .padding(.top, 6)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Theme.Typography.body.weight(.semibold))
                Text(body)
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Accessibility

    private var accessibilityCard: some View {
        Card {
            SectionHeader(title: "Accessibility")
            Text("DebtShield is built to work for everyone:")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.secondaryText)
            ForEach(Self.a11y, id: \.self) { markRow($0, "checkmark.circle.fill", Theme.statusColor(.okay)) }
            Text("If something isn't usable for you, that's a bug we want to hear about.")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private static let a11y = [
        "Full Dynamic Type, up to the largest accessibility sizes",
        "VoiceOver labels and a sensible reading order",
        "WCAG-AA contrast in light and dark — and color is never the only signal",
        "Respects Reduce Motion"
    ]

    // MARK: - Help

    private var helpCard: some View {
        Card {
            SectionHeader(
                title: "Free help",
                subtitle: "DebtShield is not an emergency service. If you're in crisis, contact local emergency services."
            )
            linkRow("Call or text 211", "Free, confidential help with rent, utilities, food, and more — anywhere in the U.S.", "phone.circle.fill", "tel:211")
            linkRow("211.org", "Find local assistance online.", "globe", "https://www.211.org")
            linkRow("HUD housing counseling", "Free, HUD-approved advice on rent, mortgages, and avoiding foreclosure.", "house.circle.fill", "https://www.hud.gov/i_want_to/talk_to_a_housing_counselor")
            linkRow("Benefits.gov", "Check what public benefits you may be eligible for.", "checkmark.seal.fill", "https://www.benefits.gov")
        }
    }

    private func linkRow(_ title: String, _ subtitle: String, _ symbol: String, _ urlString: String) -> some View {
        Group {
            if let url = URL(string: urlString) {
                Link(destination: url) {
                    HStack(spacing: Theme.Spacing.regular) {
                        AppIconBadge(systemImage: symbol, size: 34)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                                .font(Theme.Typography.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(subtitle)
                                .font(Theme.Typography.caption)
                                .foregroundStyle(Theme.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: Theme.Spacing.tight)
                        Image(systemName: urlString.hasPrefix("tel:") ? "phone.fill" : "arrow.up.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Theme.brand)
                            .accessibilityHidden(true)
                    }
                    .frame(maxWidth: .infinity, minHeight: Theme.minimumTapTarget)
                    .contentShape(Rectangle())
                }
                .accessibilityHint("Opens outside the app")
            }
        }
    }

    // MARK: - Corrections

    private var correctionsCard: some View {
        Card {
            SectionHeader(title: "Corrections & feedback")
            Text("Spotted a benchmark that looks off, or something confusing or wrong? We want to fix it.")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            NavigationLink {
                FeedbackView(store: store)
            } label: {
                DetailNavigationRow(title: "Send feedback",
                                    subtitle: "Private by design — you choose what to share, nothing is sent automatically",
                                    systemImage: "bubble.left.and.text.bubble.right")
            }
            .buttonStyle(.plain)
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack { TrustCenterView(store: .preview(.sampleTight)) }
}
#endif
