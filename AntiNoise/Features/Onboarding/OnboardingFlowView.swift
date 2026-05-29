import SwiftUI

// First-time setup for the signed-in user. Captures display name + which growth
// scopes matter to them. State is user-scoped via OnboardingStore so switching
// accounts on the same device doesn't leak the previous user's answers.
// Phase 07 reads these scopes for the priority engine.
struct OnboardingFlowView: View {
    enum Step { case topicPacks, profile, notifications }

    let uid: String
    let initialDisplayName: String?
    let onFinish: () -> Void

    @State private var step: Step = .topicPacks
    @State private var nameDraft = ""
    @State private var selectedScopes: Set<GrowthScope> = []
    @State private var selectedPacks: Set<TopicPack> = []

    var body: some View {
        Group {
            switch step {
            case .topicPacks:     topicPacksStep
            case .profile:        profileStep
            case .notifications:  NotificationPermissionStep(onFinish: onFinish)
            }
        }
        .animation(AppMotion.standard, value: step)
    }

    private var topicPacksStep: some View {
        TopicPacksSelectionView(selection: $selectedPacks) {
            OnboardingStore.setTopicPacks(selectedPacks, uid: uid)
            // Best-effort mirror so the daily ranker has signals; never blocks.
            Task { await UserProfileSyncService.syncSignals(uid: uid) }
            step = .profile
        }
        .onAppear { selectedPacks = OnboardingStore.topicPacks(uid: uid) }
    }

    private var profileStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Let's tune Anti Noise")
                        .appFont(.h1)
                    Text("Two quick questions. You can change these later in Profile.")
                        .appFont(.bodySmall)
                        .foregroundStyle(Color.textMuted)
                }

                AppTextField(
                    label: "What should we call you?",
                    text: $nameDraft,
                    placeholder: "Huy",
                    systemImage: "person",
                    autocapitalization: .words
                )

                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("Where do you want to grow?")
                        .appFont(.caption)
                        .textCase(.uppercase)
                        .foregroundStyle(Color.textMuted)
                    VStack(spacing: AppSpacing.sm) {
                        ForEach(GrowthScope.allCases, id: \.self) { scope in
                            scopeRow(scope)
                        }
                    }
                }

                PrimaryButton(
                    title: "Continue",
                    isDisabled: nameDraft.trimmingCharacters(in: .whitespaces).isEmpty || selectedScopes.isEmpty
                ) {
                    persist()
                    step = .notifications
                }
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.top, AppSpacing.xl)
            .padding(.bottom, AppSpacing.xxxl)
        }
        .background(Color.bgPrimary.ignoresSafeArea())
        .onAppear {
            let stored = OnboardingStore.displayName(uid: uid)
            if !stored.isEmpty {
                nameDraft = stored
            } else if let initial = initialDisplayName, !initial.isEmpty {
                nameDraft = initial
            }
            selectedScopes = OnboardingStore.scopes(uid: uid)
        }
    }

    private func scopeRow(_ scope: GrowthScope) -> some View {
        let isSelected = selectedScopes.contains(scope)
        return Button {
            withAnimation(AppMotion.quick) {
                if isSelected { selectedScopes.remove(scope) } else { selectedScopes.insert(scope) }
            }
        } label: {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: scope.systemImage)
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(isSelected ? Color.accent : Color.textMuted)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(scope.title).appFont(.body).fontWeight(.semibold)
                    Text(scope.subtitle).appFont(.caption).foregroundStyle(Color.textMuted)
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
        }
        .buttonStyle(.plain)
    }

    private func persist() {
        OnboardingStore.setDisplayName(nameDraft, uid: uid)
        OnboardingStore.setScopes(selectedScopes, uid: uid)
        OnboardingStore.setCompleted(true, uid: uid)
    }
}

#Preview {
    OnboardingFlowView(uid: "preview-user", initialDisplayName: nil, onFinish: {})
        .environment(NotificationService())
}
