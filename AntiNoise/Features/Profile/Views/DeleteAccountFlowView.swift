import SwiftData
import SwiftUI

struct DeleteAccountFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthStore.self) private var auth

    enum Step { case warn, exported, confirm, done }
    @State private var step: Step = .warn
    @State private var exportURL: URL?
    @State private var shareBox: ShareItemsBox?
    @State private var ackChecked = false
    @State private var isWorking = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    switch step {
                    case .warn, .exported:
                        warningSection
                        exportSection
                        if step == .exported {
                            nextStepButton
                        }
                    case .confirm:
                        confirmSection
                    case .done:
                        doneSection
                    }
                    if let errorMessage {
                        Text(errorMessage).appFont(.caption).foregroundStyle(Color.danger)
                    }
                }
                .padding(.horizontal, AppSpacing.xl)
                .padding(.top, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xxxl)
            }
            .background(Color.bgPrimary.ignoresSafeArea())
            .navigationTitle("Delete account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .tint(Color.textPrimary)
                }
            }
            .sheet(item: $shareBox) { box in
                ShareSheet(items: box.items)
            }
        }
    }

    private var warningSection: some View {
        AppCard(style: .elevated) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("This will delete your Anti Noise account.").appFont(.h3)
                Text("We'll keep your data for 7 days in case you change your mind. After that, captures, summaries, decks, flashcards, goals, and focus sessions are permanently removed.")
                    .appFont(.bodySmall)
                    .foregroundStyle(Color.textMuted)
            }
        }
    }

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Step 1 of 2 · Download your data")
                .appFont(.caption)
                .textCase(.uppercase)
                .foregroundStyle(Color.textMuted)
            PrimaryButton(title: "Download as JSON", systemImage: "square.and.arrow.down", isLoading: isWorking) {
                Task { await exportAndShare() }
            }
            if step == .exported, exportURL != nil {
                Text("Saved. Continue when ready.")
                    .appFont(.caption)
                    .foregroundStyle(Color.success)
            }
        }
    }

    private var nextStepButton: some View {
        VStack(spacing: AppSpacing.sm) {
            Text("Step 2 of 2").appFont(.caption).textCase(.uppercase).foregroundStyle(Color.textMuted)
            SecondaryButton(title: "I have my data — continue", systemImage: "arrow.right") {
                step = .confirm
            }
        }
    }

    private var confirmSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Final step").appFont(.caption).textCase(.uppercase).foregroundStyle(Color.textMuted)

            AppCard {
                Toggle(isOn: $ackChecked) {
                    Text("I understand this will delete my account in 7 days.")
                        .appFont(.bodySmall)
                }
            }

            PrimaryButton(
                title: "Delete account",
                isLoading: isWorking,
                isDisabled: !ackChecked
            ) {
                Task { await performSoftDelete() }
            }
            SecondaryButton(title: "Back to export", systemImage: "arrow.left") {
                step = .exported
            }
        }
    }

    private var doneSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Image(systemName: "envelope.open.fill").font(.system(size: 48)).foregroundStyle(Color.textMuted)
            Text("Account scheduled for deletion").appFont(.h2)
            Text("You're now signed out. Sign in within 7 days to cancel. After that we permanently delete your data on next launch.")
                .appFont(.bodySmall)
                .foregroundStyle(Color.textMuted)
            PrimaryButton(title: "Done") { dismiss() }
        }
    }

    // MARK: - Actions

    @MainActor
    private func exportAndShare() async {
        guard let user = auth.currentUser else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            let service = DataExportService(modelContainer: modelContext.container)
            let url = try service.exportAll(userID: user.id, email: user.email)
            exportURL = url
            shareBox = ShareItemsBox(items: [url])
            step = .exported
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func performSoftDelete() async {
        guard let user = auth.currentUser else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            let service = AccountDeletionService(modelContainer: modelContext.container)
            try await service.softDelete(uid: user.id, email: user.email)
            Telemetry.track(.accountDeleted)
            step = .done
        } catch {
            errorMessage = error.localizedDescription
        }
    }

}
