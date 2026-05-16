import SwiftUI

// Temporary self-serve API key entry. Phase 11 will swap for a server-issued
// token. Today: user pastes their personal OpenAI API key once; it lives in
// Keychain via SecretStore.
struct APIKeyEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: String = ""
    @State private var saveError: String?

    init() {
        _draft = State(initialValue: SecretStore.get(forKey: SecretStore.openAIAPIKey) ?? "")
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text("Paste your OpenAI API key. It stays in your device's Keychain — Anti Noise never sees it on a server.")
                    .appFont(.bodySmall)
                    .foregroundStyle(Color.textMuted)

                AppTextField(
                    label: "OpenAI API key",
                    text: $draft,
                    placeholder: "sk-...",
                    systemImage: "key",
                    isSecure: true,
                    autocapitalization: .never
                )

                if let saveError {
                    Text(saveError)
                        .appFont(.caption)
                        .foregroundStyle(Color.danger)
                }

                Spacer()

                VStack(spacing: AppSpacing.md) {
                    PrimaryButton(
                        title: "Save",
                        isDisabled: draft.trimmingCharacters(in: .whitespaces).isEmpty
                    ) {
                        save()
                    }
                    if SecretStore.get(forKey: SecretStore.openAIAPIKey) != nil {
                        SecondaryButton(title: "Remove key", systemImage: "trash") {
                            SecretStore.remove(forKey: SecretStore.openAIAPIKey)
                            dismiss()
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.top, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xl)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color.bgPrimary.ignoresSafeArea())
            .navigationTitle("API key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .tint(Color.textPrimary)
                }
            }
        }
    }

    private func save() {
        let trimmed = draft.trimmingCharacters(in: .whitespaces)
        if SecretStore.set(trimmed, forKey: SecretStore.openAIAPIKey) {
            dismiss()
        } else {
            saveError = "Couldn't save to Keychain. Try again."
        }
    }
}

#Preview {
    APIKeyEntryView()
}
