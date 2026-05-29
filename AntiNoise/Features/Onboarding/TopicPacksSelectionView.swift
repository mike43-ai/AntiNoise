import SwiftUI

/// Reusable topic-pack picker (multi-select 1–3). Used both in the first-run
/// onboarding flow and the existing-user backfill prompt so the selection UI
/// stays identical. Pure UI — persistence is the caller's job via `onContinue`.
struct TopicPacksSelectionView: View {
    @Binding var selection: Set<TopicPack>
    var headline: String = "What do you want to learn about?"
    var subtitle: String = "Pick up to 3. We'll surface 3 fresh articles a day for these."
    var ctaTitle: String = "Continue"
    let onContinue: () -> Void

    private var isValid: Bool {
        !selection.isEmpty && selection.count <= TopicPack.maxSelectable
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(headline).appFont(.h1)
                    Text(subtitle)
                        .appFont(.bodySmall)
                        .foregroundStyle(Color.textMuted)
                }

                VStack(spacing: AppSpacing.sm) {
                    ForEach(TopicPack.allCases) { pack in
                        packRow(pack)
                    }
                }

                PrimaryButton(title: ctaTitle, isDisabled: !isValid) {
                    onContinue()
                }
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.top, AppSpacing.xl)
            .padding(.bottom, AppSpacing.xxxl)
        }
        .background(Color.bgPrimary.ignoresSafeArea())
    }

    private func packRow(_ pack: TopicPack) -> some View {
        let isSelected = selection.contains(pack)
        let atLimit = selection.count >= TopicPack.maxSelectable
        return Button {
            withAnimation(AppMotion.quick) {
                if isSelected {
                    selection.remove(pack)
                } else if !atLimit {
                    selection.insert(pack)
                }
            }
        } label: {
            HStack(spacing: AppSpacing.md) {
                Text(pack.emoji)
                    .font(.system(size: 24))
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(pack.title).appFont(.body).fontWeight(.semibold)
                    Text(pack.subtitle).appFont(.caption).foregroundStyle(Color.textMuted)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.accent : Color.textMuted)
            }
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity)
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .stroke(isSelected ? Color.accent : Color.appBorder, lineWidth: isSelected ? 2 : 1)
            )
            .opacity(!isSelected && atLimit ? 0.5 : 1)
        }
        .buttonStyle(.plain)
        .disabled(!isSelected && atLimit)
    }
}

#Preview {
    TopicPacksSelectionView(selection: .constant([.aiml]), onContinue: {})
}
