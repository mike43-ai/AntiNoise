import SwiftUI

@MainActor
struct RootView: View {
    @Environment(AuthStore.self) private var auth
    @Environment(SubscriptionStore.self) private var subscription
    @State private var authSheet: AuthSheet?
    @State private var onboardingDone = false
    @State private var showTrialExpiry = false
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            switch auth.state {
            case .unknown:
                splash
            case .signedOut:
                AuthLandingView(onEmailTap: { authSheet = .signIn })
            case .signedIn(let user):
                if onboardingDone || OnboardingStore.isCompleted(uid: user.id) {
                    MainTabView()
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
            if case .signedIn(let user) = newState {
                onboardingDone = OnboardingStore.isCompleted(uid: user.id)
            } else {
                onboardingDone = false
            }
        }
        .onChange(of: subscription.trialState) { _, newState in
            if newState == .expired, !trialExpirySeen(uid: auth.currentUser?.id) {
                showTrialExpiry = true
            }
        }
        .sheet(isPresented: $showTrialExpiry) {
            TrialExpirySheet(
                onUpgrade: { showTrialExpiry = false; showPaywall = true },
                onContinueFree: { setTrialExpirySeen(true, uid: auth.currentUser?.id) }
            )
            .onAppear { Telemetry.track(.paywallShown(trigger: .trialExpiry)) }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallSheetView(offering: subscription.currentOffering)
        }
    }

    // Per-UID so signing out then back in with the same Apple ID doesn't
    // re-trigger the sheet, but a different account starts fresh.
    private func trialExpirySeen(uid: String?) -> Bool {
        guard let uid else { return true }
        return UserDefaults.standard.bool(forKey: "trialExpirySeen.\(uid)")
    }

    private func setTrialExpirySeen(_ value: Bool, uid: String?) {
        guard let uid else { return }
        UserDefaults.standard.set(value, forKey: "trialExpirySeen.\(uid)")
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
