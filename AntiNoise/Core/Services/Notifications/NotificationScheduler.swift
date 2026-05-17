import Foundation
import UserNotifications

// Persists user prefs (reminder time + per-category opt-ins) and translates
// them into UNNotificationRequests. All scheduling is idempotent — re-call
// `scheduleDailyReview` to replace the pending request.
@MainActor
struct NotificationScheduler {
    private static let center = UNUserNotificationCenter.current()

    static let dailyReviewID = "scheduled.daily_review"
    static let streakNudgeID = "scheduled.streak_nudge"

    // MARK: - Preferences (UserDefaults; per-device, not per-UID)

    private static let dailyReviewHourKey = "notifications.dailyReviewHour"
    private static let dailyReviewMinuteKey = "notifications.dailyReviewMinute"
    private static let dailyReviewEnabledKey = "notifications.dailyReviewEnabled"
    private static let streakNudgeEnabledKey = "notifications.streakNudgeEnabled"

    static var dailyReviewHour: Int {
        get { UserDefaults.standard.object(forKey: dailyReviewHourKey) as? Int ?? 19 }
        set { UserDefaults.standard.set(newValue, forKey: dailyReviewHourKey) }
    }

    static var dailyReviewMinute: Int {
        get { UserDefaults.standard.object(forKey: dailyReviewMinuteKey) as? Int ?? 0 }
        set { UserDefaults.standard.set(newValue, forKey: dailyReviewMinuteKey) }
    }

    static var isDailyReviewEnabled: Bool {
        get { UserDefaults.standard.object(forKey: dailyReviewEnabledKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: dailyReviewEnabledKey) }
    }

    static var isStreakNudgeEnabled: Bool {
        get { UserDefaults.standard.object(forKey: streakNudgeEnabledKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: streakNudgeEnabledKey) }
    }

    // MARK: - Daily review reminder

    static func scheduleDailyReview(hour: Int, minute: Int) async {
        dailyReviewHour = hour
        dailyReviewMinute = minute
        center.removePendingNotificationRequests(withIdentifiers: [dailyReviewID])

        let content = UNMutableNotificationContent()
        content.title = "Time to review"
        content.body = "Lock in what you captured. A few cards take 2 minutes."
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.dailyReview.rawValue

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: dailyReviewID, content: content, trigger: trigger)

        do {
            try await center.add(request)
        } catch {
            Telemetry.record(error: error, context: ["scope": "scheduleDailyReview"])
        }
    }

    static func cancelDailyReview() {
        center.removePendingNotificationRequests(withIdentifiers: [dailyReviewID])
    }

    // MARK: - Streak nudge (one-shot, fires today at 20:00 if streak alive)

    /// Schedules a one-shot nudge for today at 20:00 local if the user has
    /// a live streak (≥3 days) and hasn't completed a review today yet.
    /// Idempotent — replaces any pending nudge.
    static func scheduleStreakNudgeIfNeeded(streak: StreakEngine, now: Date = Date()) async {
        center.removePendingNotificationRequests(withIdentifiers: [streakNudgeID])
        guard isStreakNudgeEnabled else { return }
        guard streak.currentStreak(now: now) >= 3 else { return }
        guard !streak.didReviewToday(now: now) else { return }

        let calendar = Calendar.current
        var nudgeComponents = calendar.dateComponents([.year, .month, .day], from: now)
        nudgeComponents.hour = 20
        nudgeComponents.minute = 0
        guard let fireDate = calendar.date(from: nudgeComponents), fireDate > now else { return }

        let content = UNMutableNotificationContent()
        content.title = "Keep your streak"
        content.body = "You're on a \(streak.currentStreak(now: now))-day streak. Review one deck to extend it."
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.streakNudge.rawValue

        let interval = fireDate.timeIntervalSince(now)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: streakNudgeID, content: content, trigger: trigger)

        do {
            try await center.add(request)
        } catch {
            Telemetry.record(error: error, context: ["scope": "scheduleStreakNudge"])
        }
    }
}
