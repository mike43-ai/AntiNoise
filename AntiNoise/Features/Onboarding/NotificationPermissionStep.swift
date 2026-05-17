import SwiftUI

struct NotificationPermissionStep: View {
    @Environment(NotificationService.self) private var notifications
    let onFinish: () -> Void

    @State private var isRequesting = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                Image(systemName: "bell.badge")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(Color.accent)
                    .padding(.top, AppSpacing.xl)

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Stay on track").appFont(.h1)
                    Text("A daily nudge at 7 PM to review what you captured. Plus a streak reminder if you're close to losing it.")
                        .appFont(.body)
                        .foregroundStyle(Color.textMuted)
                }

                VStack(spacing: AppSpacing.md) {
                    bullet(systemImage: "clock", text: "Daily review reminder at 7 PM (you can change the time later).")
                    bullet(systemImage: "flame", text: "Streak nudge if you're 3+ days in and haven't reviewed by 8 PM.")
                    bullet(systemImage: "hand.raised", text: "Both are off-able in Profile settings.")
                }

                Spacer(minLength: AppSpacing.lg)

                VStack(spacing: AppSpacing.md) {
                    PrimaryButton(title: "Enable reminders", isLoading: isRequesting) {
                        Task { await request() }
                    }
                    SecondaryButton(title: "Not now") {
                        onFinish()
                    }
                }
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.bottom, AppSpacing.xxxl)
        }
        .background(Color.bgPrimary.ignoresSafeArea())
    }

    private func request() async {
        isRequesting = true
        defer { isRequesting = false }
        let granted = await notifications.requestAuthorization()
        if granted {
            await NotificationScheduler.scheduleDailyReview(
                hour: NotificationScheduler.dailyReviewHour,
                minute: NotificationScheduler.dailyReviewMinute
            )
        }
        onFinish()
    }

    private func bullet(systemImage: String, text: String) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            Image(systemName: systemImage)
                .foregroundStyle(Color.accent)
                .frame(width: 24)
            Text(text).appFont(.bodySmall).foregroundStyle(Color.textPrimary)
        }
    }
}
