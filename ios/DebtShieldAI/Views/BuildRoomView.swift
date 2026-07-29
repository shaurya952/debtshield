import SwiftUI

/// "Ways to build room" — practical, general ideas for giving the month more
/// breathing space, plus links to legitimate, free help.
///
/// This screen holds the line the rest of the app holds: it is **not advice**.
/// It never recommends a specific investment, a credit card, or a property; it
/// offers general ideas and points to reputable public resources (211, HUD,
/// Benefits.gov, the CFPB, Investor.gov). The only thing personalised is the
/// person's own biggest movable cost — a figure the app already computes on the
/// device. Nothing here leaves the phone, and no link earns the app anything.
struct BuildRoomView: View {
    let store: MoneyPlanStore

    private var plan: MoneyPlan { store.plan }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                introCard
                easiestCard
                spendLessCard
                earnMoreCard
                growCard
                helpOwedCard
                footerNote
            }
            .padding(Theme.Spacing.comfortable)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.screenGradient)
        .navigationTitle("Ways to build room")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Intro

    private var introCard: some View {
        Card {
            Text("Small, real ways to give your month a little more room.")
                .font(Theme.Typography.title)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text("General ideas and free help — not advice. Your numbers stay on your phone.")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Start where it's easiest (personalised, deterministic)

    private var easiestCard: some View {
        Card {
            iconHeader("bolt.heart.fill", "Start where it's easiest", tint: Theme.brand)
            Text(.init(easiestText))
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Uses the same movable-cost figure the home screen already surfaces, so
    /// the two never disagree. Kind, concrete, never a lecture.
    private var easiestText: String {
        let overOrTight = plan.status == .tight || plan.status == .over
        if overOrTight, let movable = plan.biggestMovableEssential {
            return "Your biggest cost you can usually move is **\(movable.label.lowercased())** at **\(money(movable.amount))**. Rent's hard to change fast, so this is often the quickest room to find — even $50 less is $50 back this month."
        } else if let movable = plan.biggestMovableEssential {
            return "You've got room this month — nice. If you'd like a cushion for a tighter one, your most flexible cost is **\(movable.label.lowercased())** (**\(money(movable.amount))**), and setting aside even a little of what's left over adds up."
        } else {
            return "Add your numbers on the home screen and this will point you at your most flexible cost — the quickest place to free up a little room."
        }
    }

    // MARK: - Spend a little less

    private var spendLessCard: some View {
        Card {
            iconHeader("scissors", "Spend a little less", tint: Theme.essentialColor(.food))
            bullet("Cancel or pause subscriptions you've stopped using.")
            bullet("Ask your providers for a better rate — phone, internet, and insurance are often negotiable.")
            bullet("Behind on an energy or utility bill? Help exists — you don't have to face it alone.")
            resourceLink(
                "Get help with bills — 211",
                "Free, confidential help with utilities, rent, and food, anywhere in the U.S.",
                "phone.circle.fill",
                "https://www.211.org"
            )
        }
    }

    // MARK: - Bring in a little more

    private var earnMoreCard: some View {
        Card {
            iconHeader("arrow.up.forward", "Bring in a little more", tint: Theme.statusColor(.okay))
            bullet("Sell things you no longer use — it clears space and adds a one-off boost.")
            bullet("Flexible hours or gig work can fit around what you already do.")
            bullet("If you're employed, it's fair to ask about a raise or more hours — the worst answer is \"not yet.\"")
            Text("Ideas only — pick what fits your life. There's no single right way to do this.")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Get help you may be owed

    private var helpOwedCard: some View {
        Card {
            iconHeader("hands.sparkles.fill", "Get help you may be owed", tint: Theme.accentWarm)
            Text("Billions in support goes unclaimed each year. Some of it may be yours — these are free and official.")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            resourceLink(
                "See what you may qualify for — Benefits.gov",
                "The official U.S. benefits finder — food, housing, healthcare, and more.",
                "checklist",
                "https://www.benefits.gov"
            )
            resourceLink(
                "Free money & housing help — HUD",
                "HUD-approved counsellors give free, judgment-free guidance.",
                "house.circle.fill",
                "https://www.hud.gov/i_want_to/talk_to_a_housing_counselor"
            )
        }
    }

    // MARK: - Grow your money (education, not advice)

    private var growCard: some View {
        Card {
            iconHeader("chart.line.uptrend.xyaxis", "Grow your money — the basics", tint: Theme.essentialColor(.debt))
            Text("Ways people build money over time, explained. Each carries real risk and works best once you've got breathing room — not as a fix for a tight month. Learn first.")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            resourceLink(
                "How investing works",
                "Stocks, funds, and retirement accounts — the plain basics, and spotting scams.",
                "chart.pie.fill",
                "https://www.investor.gov/introduction-investing"
            )
            resourceLink(
                "Using credit to your benefit",
                "Building credit and rewards — and the traps to avoid.",
                "creditcard.circle.fill",
                "https://www.consumerfinance.gov/consumer-tools/credit-reports-and-scores/"
            )
            resourceLink(
                "Real estate & home equity",
                "How owning can build equity over time — and the real costs.",
                "house.circle.fill",
                "https://www.consumerfinance.gov/owning-a-home/"
            )
        }
    }

    // MARK: - Footer

    private var footerNote: some View {
        Text("DebtShield isn't affiliated with these organisations and earns nothing from these links. They're public, reputable, and free. This screen is a starting point, not financial or legal advice.")
            .font(Theme.Typography.caption)
            .foregroundStyle(Theme.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Building blocks

    private func iconHeader(_ symbol: String, _ title: String, tint: Color) -> some View {
        HStack(spacing: Theme.Spacing.regular) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: 38, height: 38)
                .background(Theme.iconWell(tint), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                .accessibilityHidden(true)
            Text(title)
                .font(.title3.weight(.bold))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityAddTraits(.isHeader)
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.regular) {
            Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .foregroundStyle(Theme.brand)
                .padding(.top, 7)
                .accessibilityHidden(true)
            Text(text)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func resourceLink(_ title: String, _ subtitle: String, _ symbol: String, _ urlString: String) -> some View {
        if let url = URL(string: urlString) {
            Link(destination: url) {
                HStack(spacing: Theme.Spacing.regular) {
                    Image(systemName: symbol)
                        .font(.title3)
                        .foregroundStyle(Theme.brand)
                        .frame(width: 34, height: 34)
                        .background(Theme.iconWell(Theme.brand), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .accessibilityHidden(true)
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
                    Image(systemName: "arrow.up.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Theme.brand)
                        .accessibilityHidden(true)
                }
                .padding(.vertical, 4)
                .frame(minHeight: Theme.minimumTapTarget)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isLink)
            .accessibilityHint("Opens \(url.host ?? "a web page") in your browser")
        }
    }

    private func money(_ value: Double) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }
}

#if DEBUG
#Preview("Tight") {
    NavigationStack { BuildRoomView(store: .preview(.sampleTight)) }
}

#Preview("Okay") {
    NavigationStack { BuildRoomView(store: .preview(.sampleOkay)) }
}
#endif
