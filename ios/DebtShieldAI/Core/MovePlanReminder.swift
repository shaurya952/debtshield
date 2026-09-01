import Foundation
import UserNotifications

/// Local nudges tied to a **move goal** — the honest version of "come back and
/// check". Two kinds, both on-device, both cancellable:
///
/// 1. A gentle **monthly** reminder to log savings toward the goal.
/// 2. A one-off **data-refreshed** alert, fired only when an app update genuinely
///    ships new bundled cost figures — never a fabricated "rent rose 6%" claim,
///    because the data is static between releases and inventing a change would
///    break the honesty rule.
enum MovePlanReminder {
    static let monthlyID = "debtshield.movePlan.monthly"
    static let refreshID = "debtshield.movePlan.dataRefresh"

    /// Ask permission (if not asked yet) and schedule the monthly goal nudge.
    /// A denied prompt just means no nudge — nothing else changes.
    static func enable(placeName: String) async {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        guard granted else { return }
        center.removePendingNotificationRequests(withIdentifiers: [monthlyID])

        let content = UNMutableNotificationContent()
        content.title = "Your move goal"
        content.body = "Still working toward \(placeName)? Open Headroom to log this month toward your fund — no pressure, no streaks."
        content.sound = .default

        var when = DateComponents()
        when.day = 1
        when.hour = 10
        let trigger = UNCalendarNotificationTrigger(dateMatching: when, repeats: true)
        try? await center.add(UNNotificationRequest(identifier: monthlyID, content: content, trigger: trigger))
    }

    /// Cancel both nudges — called when the goal is cleared.
    static func cancel() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [monthlyID, refreshID])
    }

    /// Fire a one-off alert a couple of hours out when the bundled cost data was
    /// refreshed by an app update, so a saved goal gets a fresh look. Silent unless
    /// notifications are already allowed.
    static func notifyDataRefreshed(placeName: String) async {
        guard await MonthlyReminder.isAuthorized() else { return }
        let content = UNMutableNotificationContent()
        content.title = "Cost figures refreshed"
        content.body = "Headroom's rent and pay data were just updated — your move goal to \(placeName) may have shifted. Take a look."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2 * 60 * 60, repeats: false)
        try? await UNUserNotificationCenter.current()
            .add(UNNotificationRequest(identifier: refreshID, content: content, trigger: trigger))
    }
}

/// Version of the bundled cost data (rent, wages, energy, metros). Bump this
/// whenever the shipped datasets change so a saved move goal can be re-checked.
enum CostData {
    /// v1: launch datasets. v2: added metro-area rollups + BLS employment counts.
    static let version = 2
}
