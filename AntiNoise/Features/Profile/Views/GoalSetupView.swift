import SwiftData
import SwiftUI

struct GoalSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthStore.self) private var auth

    @State private var draft: String = ""
    @State private var focusScope: ClassificationScope = .personal
    @State private var goals: [ClassificationScope: [LearningGoal]] = [:]
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    Text("Tell us what you're working toward. The priority engine surfaces captures that align with these.")
                        .appFont(.bodySmall)
                        .foregroundStyle(Color.textMuted)

                    addGoalCard

                    ForEach(ClassificationScope.allCases, id: \.self) { scope in
                        scopeSection(scope)
                    }
                }
                .padding(.horizontal, AppSpacing.xl)
                .padding(.top, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xxxl)
            }
            .background(Color.bgPrimary.ignoresSafeArea())
            .navigationTitle("Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .tint(Color.textPrimary)
                }
            }
            .onAppear(perform: reload)
        }
    }

    private var addGoalCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Add a goal").appFont(.caption).textCase(.uppercase).foregroundStyle(Color.textMuted)

                Picker("Scope", selection: $focusScope) {
                    ForEach(ClassificationScope.allCases, id: \.self) { scope in
                        Text(scope.title).tag(scope)
                    }
                }
                .pickerStyle(.segmented)

                AppTextField(
                    label: "Goal",
                    text: $draft,
                    placeholder: "e.g. become a better Swift developer",
                    systemImage: "target",
                    autocapitalization: .sentences
                )

                if let errorMessage {
                    Text(errorMessage)
                        .appFont(.caption)
                        .foregroundStyle(Color.danger)
                }

                PrimaryButton(
                    title: "Add",
                    isDisabled: draft.trimmingCharacters(in: .whitespaces).isEmpty
                ) { addGoal() }
            }
        }
    }

    private func scopeSection(_ scope: ClassificationScope) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Image(systemName: scope.systemImage)
                Text(scope.title).appFont(.h3)
                Spacer()
                Text("\(goals[scope]?.count ?? 0) / \(LearningGoalRepository.maxPerScope)")
                    .appFont(.caption)
                    .foregroundStyle(Color.textMuted)
            }

            let items = goals[scope] ?? []
            if items.isEmpty {
                AppCard(style: .outline) {
                    Text("No goals here yet.")
                        .appFont(.bodySmall)
                        .foregroundStyle(Color.textMuted)
                }
            } else {
                VStack(spacing: AppSpacing.xs) {
                    ForEach(items) { goal in
                        AppCard {
                            HStack(spacing: AppSpacing.sm) {
                                Text(goal.title)
                                    .appFont(.body)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Button {
                                    remove(goal: goal)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(Color.danger)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }

    private func addGoal() {
        let uid = currentUID()
        do {
            let repo = LearningGoalRepository(context: modelContext)
            if try repo.add(scope: focusScope, title: draft, uid: uid) == nil {
                errorMessage = "You've reached the max of \(LearningGoalRepository.maxPerScope) goals for this scope."
            } else {
                draft = ""
                errorMessage = nil
                reload()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func remove(goal: LearningGoal) {
        let repo = LearningGoalRepository(context: modelContext)
        try? repo.remove(id: goal.id)
        reload()
    }

    private func reload() {
        let uid = currentUID()
        let repo = LearningGoalRepository(context: modelContext)
        var bucket: [ClassificationScope: [LearningGoal]] = [:]
        for scope in ClassificationScope.allCases {
            bucket[scope] = repo.goals(uid: uid, scope: scope)
        }
        goals = bucket
    }

    private func currentUID() -> String { auth.currentUser?.id ?? "" }
}

#Preview {
    GoalSetupView()
        .environment(AuthStore())
}
