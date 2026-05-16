import SwiftUI

struct AppEmptyState: View {
    let systemImage: String
    let title: String
    var message: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Color.textMuted)
                .padding(.bottom, AppSpacing.xs)

            Text(title)
                .appFont(.h3)
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)

            if let message {
                Text(message)
                    .appFont(.bodySmall)
                    .foregroundStyle(Color.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xl)
            }

            if let actionTitle, let action {
                PrimaryButton(title: actionTitle, fullWidth: false, action: action)
                    .padding(.top, AppSpacing.sm)
            }
        }
        .padding(AppSpacing.xl)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    AppEmptyState(
        systemImage: "tray",
        title: "Nothing captured yet",
        message: "Share a link or screenshot to Anti Noise to start your knowledge stack.",
        actionTitle: "Capture First",
        action: {}
    )
    .background(Color.bgPrimary)
}
