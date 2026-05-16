import SwiftUI

struct RootView: View {
    @Environment(AuthStore.self) private var auth
    @State private var authSheet: AuthSheet?
    @State private var onboardingDone = false

    var body: some View {
        ZStack {
            switch auth.state {
            case .unknown:
                splash
            case .signedOut:
                AuthLandingView(onEmailTap: { authSheet = .signIn })
            case .signedIn(let user):
                if onboardingDone || OnboardingStore.isCompleted(uid: user.id) {
                    SignedInPlaceholder()
                } else {
                    OnboardingFlowView(
                        uid: user.id,
                        initialDisplayName: user.displayName,
                        onFinish: { onboardingDone = true }
                    )
                }
            }
        }
        .animation(AppMotion.standard, value: auth.state)
        .sheet(item: $authSheet) { sheet in
            NavigationStack {
                switch sheet {
                case .signIn:
                    SignInView(onSwitchToSignUp: { authSheet = .signUp })
                case .signUp:
                    SignUpView(onSwitchToSignIn: { authSheet = .signIn })
                }
            }
        }
        .onChange(of: auth.state) { _, newState in
            // Reset transient flag when the user changes; persistent state lives in OnboardingStore.
            if case .signedIn(let user) = newState {
                onboardingDone = OnboardingStore.isCompleted(uid: user.id)
            } else {
                onboardingDone = false
            }
        }
    }

    private var splash: some View {
        VStack {
            Spacer()
            AppLoadingIndicator(size: 40)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bgPrimary.ignoresSafeArea())
    }
}

private enum AuthSheet: String, Identifiable {
    case signIn, signUp
    var id: String { rawValue }
}

// Placeholder shown after onboarding — replaced by MainTabView in Phase 04.
private struct SignedInPlaceholder: View {
    @Environment(AuthStore.self) private var auth

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Text("Signed in")
                .appFont(.h1)
            if let email = auth.currentUser?.email {
                Text(email)
                    .appFont(.bodySmall)
                    .foregroundStyle(Color.textMuted)
            }
            SecondaryButton(title: "Sign out", systemImage: "rectangle.portrait.and.arrow.right", fullWidth: false) {
                try? auth.signOut()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bgPrimary.ignoresSafeArea())
    }
}
