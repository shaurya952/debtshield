import SwiftUI

/// What the app stores and what it does not.
///
/// Every claim here was checked against the source before being written. The
/// app contains no `URLSession`, no analytics SDK, no location, contacts,
/// camera, or pasteboard access, and writes exactly three `UserDefaults` keys —
/// all of which are listed below by name. If that ever changes, this screen has
/// to change with it.
struct PrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                headline
                noAccountCard
                storedCard
                notCollectedCard
                doNotEnterCard
                dataOriginCard
                childrenCard
            }
            .padding(Theme.Spacing.comfortable)
        }
        .background(Theme.screenGradient)
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.large)
    }

    private var headline: some View {
        Card {
            HStack(spacing: Theme.Spacing.tight) {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(Theme.riskColor(.low))
                    .accessibilityHidden(true)
                Text("Nothing leaves your device")
                    .font(.title3.weight(.bold))
                    .accessibilityAddTraits(.isHeader)
            }
            Text("DebtShield AI has no servers, makes no network requests, and contains no analytics or tracking. It works fully offline, including in Airplane Mode.")
                .font(.subheadline)
        }
    }

    private var noAccountCard: some View {
        PrivacySection(
            systemImage: "person.crop.circle.badge.xmark",
            title: "No account, no sign-in",
            message: "There is nothing to register for and no way to log in. The app does not know who you are, and has no concept of a user."
        )
    }

    private var storedCard: some View {
        Card {
            SectionHeader(
                title: "What is saved on this device",
                subtitle: "A few small preferences, stored by iOS in the app's own settings"
            )

            storedItem(
                "Saved counties",
                "The county codes you starred — for example 22035 for East Carroll Parish. Just the codes, nothing else."
            )
            storedItem(
                "Recently viewed",
                "The county codes of the last ten counties you opened, so you can get back to them."
            )
            storedItem(
                "Last viewed county",
                "The county code you were last looking at, so the app reopens where you left off."
            )
            storedItem(
                "Recommendations view",
                "Whether you last read the policymaker or resident version."
            )
            storedItem(
                "Introduction seen",
                "A single yes/no so the welcome screen only appears once."
            )

            Divider()

            Text("That is the complete list. All of them are removed when the app is deleted, and none of them is transmitted anywhere.")
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
        }
    }

    private func storedItem(_ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.regular) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Theme.riskColor(.low))
                .frame(width: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(body)
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var notCollectedCard: some View {
        Card {
            SectionHeader(title: "What the app never touches")
            ForEach(Self.notCollected, id: \.self) { item in
                HStack(alignment: .top, spacing: Theme.Spacing.regular) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Theme.secondaryText)
                        .frame(width: 24)
                        .accessibilityHidden(true)
                    Text(item)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
            }
        }
    }

    private static let notCollected = [
        "Your name, email address, or phone number",
        "Your location — the app never asks for it and cannot see it",
        "Your income, debts, credit history, or any financial details",
        "Your contacts, photos, calendar, or health data",
        "Usage analytics, crash reporting, or advertising identifiers",
        "Anything you type into the Ask DebtShield box, which is answered on-device and never stored"
    ]

    /// Requirement: the app should not collect personal financial information —
    /// so it says plainly that there is nowhere to put it and no reason to.
    private var doNotEnterCard: some View {
        Card {
            HStack(spacing: Theme.Spacing.tight) {
                Image(systemName: "hand.raised.fill")
                    .foregroundStyle(Theme.riskColor(.medium))
                    .accessibilityHidden(true)
                Text("Please do not enter personal details")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
            }
            Text("DebtShield AI never asks for personal or financial information, and there is no field anywhere in the app that needs it.")
                .font(.subheadline)
            Text("The Ask DebtShield box takes questions about counties. Please do not type account numbers, balances, or anything identifying into it — it cannot use them, and it will tell you it can't help with an individual's situation.")
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
        }
    }

    private var dataOriginCard: some View {
        PrivacySection(
            systemImage: "shippingbox",
            title: "The county data is built in",
            message: "All county figures are public statistics from the U.S. Census Bureau, included inside the app when it is installed. Nothing is downloaded while you use it, so no request reveals which counties you looked at."
        )
    }

    private var childrenCard: some View {
        PrivacySection(
            systemImage: "figure.and.child.holdinghands",
            title: "Children",
            message: "Because the app collects nothing at all, it collects nothing from children either. There is no age gate because there is no data to protect."
        )
    }
}

struct PrivacySection: View {
    let systemImage: String
    let title: String
    let message: String

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        Card {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: Theme.Spacing.tight) { icon; text }
            } else {
                HStack(alignment: .top, spacing: Theme.Spacing.regular) { icon; text }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var icon: some View {
        Image(systemName: systemImage)
            .font(.title2)
            .foregroundStyle(Theme.brand)
            .frame(width: 32)
            .accessibilityHidden(true)
    }

    private var text: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
