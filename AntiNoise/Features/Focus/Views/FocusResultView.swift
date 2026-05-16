import SwiftUI

struct FocusResultView: View {
    let plannedSeconds: Int
    let elapsedSeconds: Int
    let completed: Bool
    let linkedDeckID: UUID?
    let onReview: (UUID) -> Void
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            VStack(spacing: AppSpacing.sm) {
                Image(systemName: completed ? "checkmark.seal.fill" : "moon.zzz.fill")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(completed ? Color.success : Color.textMuted)
                Text(completed ? "Session complete" : "Session ended early")
                    .appFont(.h1)
                    .multilineTextAlignment(.center)
                Text("\(elapsedSeconds / 60) min of \(plannedSeconds / 60) planned")
                    .appFont(.bodySmall)
                    .foregroundStyle(Color.textMuted)
            }

            Spacer()

            VStack(spacing: AppSpacing.md) {
                if let deckID = linkedDeckID {
                    PrimaryButton(title: "Review the deck", systemImage: "rectangle.stack.fill") {
                        onReview(deckID)
                    }
                }
                SecondaryButton(title: "Done", action: onDone)
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.bottom, AppSpacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bgPrimary.ignoresSafeArea())
    }
}
