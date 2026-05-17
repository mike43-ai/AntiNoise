import SwiftUI

struct TrialExpirySheet: View {
    let onUpgrade: () -> Void
    let onContinueFree: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                Spacer()
                Image(systemName: "hourglass")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(Color.accent)
                Text("Your 7-day Pro trial just ended.").appFont(.h1)
                Text("You can keep using Anti Noise on Free: 3 captures a day, 5 AI summaries a month. Or stay Pro for unlimited everything.")
                    .appFont(.body)
                    .foregroundStyle(Color.textMuted)
                Spacer()
                VStack(spacing: AppSpacing.md) {
                    PrimaryButton(title: "Stay on Pro") { onUpgrade() }
                    SecondaryButton(title: "Continue on Free") {
                        onContinueFree(); dismiss()
                    }
                }
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.bottom, AppSpacing.xl)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(Color.bgPrimary.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .tint(Color.textPrimary)
                }
            }
        }
    }
}
