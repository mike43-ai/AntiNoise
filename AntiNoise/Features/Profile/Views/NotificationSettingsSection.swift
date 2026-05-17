import SwiftUI
import UserNotifications

@MainActor
struct NotificationSettingsSection: View {
    @Environment(NotificationService.self) private var notifications

    @State private var dailyEnabled = NotificationScheduler.isDailyReviewEnabled
    @State private var streakEnabled = NotificationScheduler.isStreakNudgeEnabled
    @State private var reminderTime: Date = {
        var components = DateComponents()
        components.hour = NotificationScheduler.dailyReviewHour
        components.minute = NotificationScheduler.dailyReviewMinute
        return Calendar.current.date(from: components) ?? Date()
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Notifications").appFont(.caption).textCase(.uppercase).foregroundStyle(Color.textMuted)

            if notifications.authorizationStatus == .denied {
                AppCard {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Notifications are turned off").appFont(.body).fontWeight(.semibold)
                        Text("Enable them in iOS Settings → Anti Noise to get review reminders and streak nudges.")
                            .appFont(.caption).foregroundStyle(Color.textMuted)
                    }
                }
            } else {
                AppCard {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Toggle(isOn: $dailyEnabled) {
                            label(title: "Daily review reminder", subtitle: "A nudge to keep your decks moving.")
                        }
                        .tint(Color.accent)

                        if dailyEnabled {
                            DatePicker("Reminder time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                                .appFont(.bodySmall)
                                .tint(Color.accent)
                        }

                        Divider().background(Color.appBorder)

                        Toggle(isOn: $streakEnabled) {
                            label(title: "Streak nudge", subtitle: "Only fires at 8 PM when your streak is 3+ days and you haven't reviewed yet.")
                        }
                        .tint(Color.accent)
                    }
                }
            }
        }
        .padding(.top, AppSpacing.lg)
        .task {
            await notifications.refreshAuthorizationStatus()
        }
        .onChange(of: dailyEnabled) { _, enabled in
            NotificationScheduler.isDailyReviewEnabled = enabled
            Task {
                if enabled, notifications.authorizationStatus == .authorized {
                    await applyDailySchedule()
                } else {
                    NotificationScheduler.cancelDailyReview()
                }
            }
        }
        .onChange(of: reminderTime) { _, _ in
            guard dailyEnabled, notifications.authorizationStatus == .authorized else { return }
            Task { await applyDailySchedule() }
        }
        .onChange(of: streakEnabled) { _, enabled in
            NotificationScheduler.isStreakNudgeEnabled = enabled
        }
    }

    private func applyDailySchedule() async {
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        await NotificationScheduler.scheduleDailyReview(
            hour: components.hour ?? 19,
            minute: components.minute ?? 0
        )
    }

    private func label(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).appFont(.body)
            Text(subtitle).appFont(.caption).foregroundStyle(Color.textMuted)
        }
    }
}
