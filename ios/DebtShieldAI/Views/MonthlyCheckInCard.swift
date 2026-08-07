import SwiftUI

/// Settings for the optional monthly reminder. Private and on-device: it
/// schedules a local notification, asks permission only when turned on, and can
/// be turned off any time. No streaks, no pressure.
struct MonthlyCheckInCard: View {
    @AppStorage("debtshield.reminderEnabled") private var enabled = false
    @AppStorage("debtshield.reminderDay") private var day = 1
    @State private var showDeniedNote = false

    var body: some View {
        Card {
            SectionHeader(
                title: "Monthly check-in",
                subtitle: "An optional, private reminder to update your numbers. No streaks, no pressure — turn it off any time."
            )

            Toggle(isOn: $enabled) {
                Text("Remind me each month")
                    .font(Theme.Typography.body.weight(.semibold))
            }
            .tint(Theme.brand)
            .frame(minHeight: Theme.minimumTapTarget)
            .onChange(of: enabled) { _, on in
                Task { @MainActor in await apply(on) }
            }

            if enabled {
                Divider()
                Stepper(value: $day, in: 1...28) {
                    Text("On day \(day) of each month, around 10 AM")
                        .font(Theme.Typography.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(minHeight: Theme.minimumTapTarget)
                .onChange(of: day) { _, newDay in
                    MonthlyReminder.schedule(day: newDay)
                }
            }

            if showDeniedNote {
                Text("Notifications are turned off for DebtShield. To get the reminder, enable them in iOS Settings ▸ DebtShield ▸ Notifications.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @MainActor
    private func apply(_ on: Bool) async {
        if on {
            let granted = await MonthlyReminder.requestAuthorization()
            if granted {
                MonthlyReminder.schedule(day: day)
                showDeniedNote = false
            } else {
                enabled = false
                showDeniedNote = true
            }
        } else {
            MonthlyReminder.cancel()
            showDeniedNote = false
        }
    }
}

#if DEBUG
#Preview {
    ScrollView { MonthlyCheckInCard().padding() }
        .background(Theme.screenBackground)
}
#endif
