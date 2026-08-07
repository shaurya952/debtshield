import Foundation
import UserNotifications

/// A single, on-device monthly reminder to update your numbers.
///
/// It is a **local** notification — scheduled by iOS on this device, with no
/// server and nothing transmitted. The person turns it on, picks the day, and
/// can turn it off any time. The copy is plain and pressure-free: there are no
/// streaks, no guilt, and no penalty for a missed month (see `CLAUDE.md`).
enum MonthlyReminder {
    static let identifier = "debtshield.monthlyCheckIn"

    /// Ask for permission to show notifications. Returns whether it was granted.
    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    /// Whether the user has granted notification permission.
    static func isAuthorized() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return true
        default: return false
        }
    }

    /// Schedule (or reschedule) the monthly reminder on `day` of the month at
    /// `hour`:00, in the device's local time. Replaces any existing one.
    static func schedule(day: Int, hour: Int = 10) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        var when = DateComponents()
        when.day = min(max(day, 1), 28)   // 28 so it exists in every month
        when.hour = hour

        let content = UNMutableNotificationContent()
        content.title = "Monthly check-in"
        content.body = "When you have a minute, update this month's numbers to see where you stand."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: when, repeats: true)
        center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }

    /// Cancel the reminder.
    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
