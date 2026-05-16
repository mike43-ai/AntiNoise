import SwiftUI

struct ProfileRootView: View {
    @Environment(AuthStore.self) private var auth

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

                    AppEmptyState(
                        systemImage: "person.crop.circle",
                        title: "Profile coming soon",
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
        }
    }
}

#Preview {
    ProfileRootView()
        .environment(AuthStore())
}
