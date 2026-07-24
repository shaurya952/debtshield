import SwiftUI

/// What the app stores and what it doesn't.
///
/// Every claim here was checked against the source. The app contains no
/// `URLSession`, no analytics SDK, no location, contacts, camera, or pasteboard
/// access. It writes the person's money numbers, their chosen area, and a
/// "seen the intro" flag to `UserDefaults` — all on the device, none of it
/// transmitted. If that ever changes, this screen has to change with it.
struct PrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                headline
                noAccountCard
                storedCard
                notCollectedCard
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
                    .foregroundStyle(Theme.statusColor(.okay))
                    .accessibilityHidden(true)
                Text("Your numbers stay on your phone")
                    .font(.title3.weight(.bold))
                    .accessibilityAddTraits(.isHeader)
            }
            Text("This is the whole point. DebtShield has no servers, makes no network requests, and has no analytics or tracking. The numbers you enter are saved only on this device and are never uploaded or shared. It works fully offline, including in Airplane Mode.")
                .font(Theme.Typography.subheadline)
        }
    }

    private var noAccountCard: some View {
        PrivacySection(
            systemImage: "person.crop.circle.badge.xmark",
            title: "No account, no sign-in",
            message: "There's nothing to register for and no way to log in. The app doesn't know who you are, and it has no concept of a user."
        )
    }

    private var storedCard: some View {
        Card {
            SectionHeader(
                title: "What's saved on this device",
                subtitle: "Stored by iOS in the app's own settings — nowhere else"
            )

            storedItem(
                "Your name and email",
                "What you entered when you set up — so the app can greet you. There's no account and no password; it's just saved here, never sent anywhere."
            )
            storedItem(
                "Your numbers",
                "The income and monthly essentials you enter — income, rent or mortgage, food, energy, and debt payments. Kept so the app remembers your month between visits."
            )
            storedItem(
                "Your area",
                "If you choose where you live for the rent and energy comparison, the county is saved — just the place, to look up the local typical."
            )
            storedItem(
                "Welcome screen seen",
                "A single yes/no so the intro only appears once."
            )

            Divider()

            Text("That's the complete list. All of it is removed when you delete the app, and none of it is transmitted anywhere. You can wipe it any time by clearing your numbers.")
                .font(Theme.Typography.footnote)
                .foregroundStyle(Theme.secondaryText)
        }
    }

    private func storedItem(_ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.regular) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Theme.statusColor(.okay))
                .frame(width: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.Typography.subheadline.weight(.semibold))
                Text(body)
                    .font(Theme.Typography.footnote)
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
            SectionHeader(title: "What the app never does")
            ForEach(Self.notCollected, id: \.self) { item in
                HStack(alignment: .top, spacing: Theme.Spacing.regular) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Theme.secondaryText)
                        .frame(width: 24)
                        .accessibilityHidden(true)
                    Text(item)
                        .font(Theme.Typography.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
            }
        }
    }

    private static let notCollected = [
        "Upload or share your numbers — they never leave this device",
        "Ask for your name, email, or phone number",
        "Track your location — it never asks and can't see it",
        "Touch your contacts, photos, calendar, or health data",
        "Collect usage analytics, crash reports, or advertising identifiers",
        "Send anything you type into Ask DebtShield anywhere — it's answered on-device and never stored"
    ]

    private var childrenCard: some View {
        PrivacySection(
            systemImage: "figure.and.child.holdinghands",
            title: "Children",
            message: "Because nothing is collected or transmitted, nothing is collected from children either. There's no age gate because there's no data leaving the device to protect."
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
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
