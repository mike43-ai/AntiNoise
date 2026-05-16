import SwiftUI

struct ReviewSummaryView: View {
    let total: Int
    let correct: Int
    let lapses: Int
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            VStack(spacing: AppSpacing.sm) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(Color.success)
                Text("Session complete")
                    .appFont(.h1)
            }

            HStack(spacing: AppSpacing.lg) {
                stat(label: "Reviewed", value: total)
                stat(label: "Correct",  value: correct)
                stat(label: "Lapses",   value: lapses)
            }

            Spacer()

            PrimaryButton(title: "Done", action: onDone)
                .padding(.horizontal, AppSpacing.xl)
                .padding(.bottom, AppSpacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func stat(label: String, value: Int) -> some View {
        VStack(spacing: 2) {
            Text("\(value)").appFont(.h1)
            Text(label).appFont(.caption).foregroundStyle(Color.textMuted).textCase(.uppercase)
        }
        .padding(AppSpacing.md)
        .frame(minWidth: 90)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .stroke(Color.appBorder, lineWidth: 1)
        )
    }
}
