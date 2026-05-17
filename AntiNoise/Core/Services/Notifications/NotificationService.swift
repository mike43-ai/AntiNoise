import Foundation
import Observation
import UserNotifications

// Categories declared as compile-time constants so schedulers + tap handlers
// can't drift. Used as identifiers for both UNNotificationCategory and the
// telemetry `category` param.
enum NotificationCategory: String, CaseIterable {
    case dailyReview = "daily_review_reminder"
    case streakNudge = "streak_nudge"
}

@Observable
@MainActor
final class NotificationService: NSObject {
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    private let center = UNUserNotificationCenter.current()

    func bootstrap() {
        center.delegate = self
        center.setNotificationCategories(Set(NotificationCategory.allCases.map {
            UNNotificationCategory(identifier: $0.rawValue, actions: [], intentIdentifiers: [])
        }))
        Task { await refreshAuthorizationStatus() }
    }

    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await refreshAuthorizationStatus()
            if granted {
                Telemetry.track(.notificationOptIn(
                    categories: NotificationCategory.allCases.map(\.rawValue)
                ))
            }
            return granted
        } catch {
            Telemetry.record(error: error, context: ["scope": "notification.requestAuthorization"])
            return false
        }
    }
}

extension NotificationService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show in-foreground notifications as banners so the user actually
        // sees the streak nudge if they have the app open.
        completionHandler([.banner, .sound, .list])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let categoryID = response.notification.request.content.categoryIdentifier
        Telemetry.track(.notificationTapped(category: categoryID))
        completionHandler()
    }
}
