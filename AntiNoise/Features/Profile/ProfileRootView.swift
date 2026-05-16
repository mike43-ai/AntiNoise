import SwiftUI

struct ProfileRootView: View {
    @Environment(AuthStore.self) private var auth
    @State private var isAPIKeySheetPresented = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    if let user = auth.currentUser {
                        AppCard {
                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                Text(user.displayName ?? "You")
                                    .appFont(.h2)
                                if let email = user.email {
                                    Text(email)
                                        .appFont(.bodySmall)
                                        .foregroundStyle(Color.textMuted)
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("AI")
                            .appFont(.caption)
                            .textCase(.uppercase)
                            .foregroundStyle(Color.textMuted)
                        SecondaryButton(
                            title: hasKey ? "Manage OpenAI key" : "Add OpenAI key",
                            systemImage: "key"
                        ) {
                            isAPIKeySheetPresented = true
                        }
                    }

                    AppEmptyState(
                        systemImage: "person.crop.circle",
                        title: "More coming",
                        message: "Stats, settings, subscription, and account controls land in Phase 10."
                    )

                    SecondaryButton(
                        title: "Sign out",
                        systemImage: "rectangle.portrait.and.arrow.right"
                    ) {
                        try? auth.signOut()
                    }
                    .padding(.top, AppSpacing.lg)
                }
                .padding(AppSpacing.xl)
            }
            .background(Color.bgPrimary)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $isAPIKeySheetPresented) {
                APIKeyEntryView()
            }
        }
    }

    private var hasKey: Bool {
        SecretStore.get(forKey: SecretStore.openAIAPIKey)?.isEmpty == false
    }
}

#Preview {
    ProfileRootView()
        .environment(AuthStore())
}
