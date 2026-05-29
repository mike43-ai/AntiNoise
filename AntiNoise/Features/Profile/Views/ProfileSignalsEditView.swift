import SwiftUI

/// Edit Daily Knowledge feed signals: topic packs (required) plus optional
/// role / experience / goal. Persists to `OnboardingStore` and mirrors to
/// Firestore via `UserProfileSyncService` for the backend ranker.
struct ProfileSignalsEditView: View {
    let uid: String
    @Environment(\.dismiss) private var dismiss

    @State private var packs: Set<TopicPack> = []
    @State private var role: UserRole?
    @State private var level: ExperienceLevel?
    @State private var goal: UserGoal?

    var body: some View {
        NavigationStack {
            Form {
                Section("Topics (pick up to \(TopicPack.maxSelectable))") {
                    ForEach(TopicPack.allCases) { pack in
                        Button { toggle(pack) } label: {
                            HStack {
                                Text("\(pack.emoji)  \(pack.title)")
                                Spacer()
                                if packs.contains(pack) {
                                    Image(systemName: "checkmark").foregroundStyle(Color.accent)
                                }
                            }
                        }
                        .tint(.primary)
                        .disabled(!packs.contains(pack) && packs.count >= TopicPack.maxSelectable)
                    }
                }

                Section("Role (optional)") {
                    Picker("Role", selection: $role) {
                        Text("Not set").tag(UserRole?.none)
                        ForEach(UserRole.allCases) { r in Text(r.title).tag(UserRole?.some(r)) }
                    }
                }

                Section("Experience (optional)") {
                    Picker("Experience", selection: $level) {
                        Text("Not set").tag(ExperienceLevel?.none)
                        ForEach(ExperienceLevel.allCases) { l in Text(l.title).tag(ExperienceLevel?.some(l)) }
                    }
                }

                Section("Goal (optional)") {
                    Picker("Goal", selection: $goal) {
                        Text("Not set").tag(UserGoal?.none)
                        ForEach(UserGoal.allCases) { g in Text(g.title).tag(UserGoal?.some(g)) }
                    }
                }
            }
            .navigationTitle("Improve your feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .onAppear {
                packs = OnboardingStore.topicPacks(uid: uid)
                role = OnboardingStore.role(uid: uid)
                level = OnboardingStore.experienceLevel(uid: uid)
                goal = OnboardingStore.goal(uid: uid)
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button("Save") { save() }.disabled(packs.isEmpty)
        }
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
        }
    }

    private func toggle(_ pack: TopicPack) {
        if packs.contains(pack) {
            packs.remove(pack)
        } else if packs.count < TopicPack.maxSelectable {
            packs.insert(pack)
        }
    }

    private func save() {
        OnboardingStore.setTopicPacks(packs, uid: uid)
        OnboardingStore.setRole(role, uid: uid)
        OnboardingStore.setExperienceLevel(level, uid: uid)
        OnboardingStore.setGoal(goal, uid: uid)
        Task { await UserProfileSyncService.syncSignals(uid: uid) }
        dismiss()
    }
}
