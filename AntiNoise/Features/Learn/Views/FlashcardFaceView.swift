import SwiftUI

struct FlashcardFaceView: View {
    let title: String
    let text: String
    let footer: String?
    let isAnswer: Bool

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            HStack {
                Text(title)
                    .appFont(.caption)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.textMuted)
                Spacer()
                Image(systemName: isAnswer ? "lightbulb.fill" : "questionmark.circle")
                    .foregroundStyle(isAnswer ? Color.accent : Color.textMuted)
            }
            Spacer()
            Text(text)
                .appFont(.h2)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.textPrimary)
                .padding(.horizontal, AppSpacing.md)
            Spacer()
            if let footer {
                Text(footer)
                    .appFont(.caption)
                    .foregroundStyle(Color.textMuted)
            }
        }
        .padding(AppSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .stroke(Color.appBorder, lineWidth: 1)
        )
    }
}
