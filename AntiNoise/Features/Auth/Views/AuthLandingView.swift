import AuthenticationServices
import SwiftUI

struct AuthLandingView: View {
    @Environment(AuthStore.self) private var auth
    @State private var isAppleLoading = false
    @State private var error: AuthError?

    let onEmailTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: AppSpacing.lg) {
                Text("ANTi NOISE")
                    .appFont(.h2)
                    .tracking(4)
                    .foregroundStyle(Color.textPrimary)

                Text("Cut The Noise.\nFocus on What Matters.")
                    .appFont(.display)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.textPrimary)
                    .padding(.horizontal, AppSpacing.md)
            }

            Spacer()

            VStack(spacing: AppSpacing.md) {
                appleButton
                SecondaryButton(title: "Continue with Email", systemImage: "envelope") {
                    onEmailTap()
                }
                Text("By continuing you agree to our Terms & Privacy.")
                    .appFont(.caption)
                    .foregroundStyle(Color.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.top, AppSpacing.xs)
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.bottom, AppSpacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bgPrimary.ignoresSafeArea())
        .alert("Sign in failed", isPresented: errorBinding, presenting: error) { _ in
            Button("OK", role: .cancel) { error = nil }
        } message: { err in
            Text(err.localizedDescription)
        }
    }

    private var appleButton: some View {
        Button {
            Task { await runAppleSignIn() }
        } label: {
            HStack(spacing: AppSpacing.sm) {
                if isAppleLoading {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 18, weight: .medium))
                }
                Text("Continue with Apple")
                    .appFont(.bodySmall)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.horizontal, AppSpacing.lg)
            .background(Color.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isAppleLoading)
    }

    @MainActor
    private func runAppleSignIn() async {
        isAppleLoading = true
        defer { isAppleLoading = false }
        do {
            try await auth.signInWithApple()
        } catch let err as AuthError {
            // Don't surface a "cancelled" alert — user just dismissed the sheet.
            if case .appleCancelled = err { return }
            error = err
        } catch {
            self.error = AuthError(error)
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { error != nil }, set: { if !$0 { error = nil } })
    }
}

#Preview {
    AuthLandingView(onEmailTap: {})
        .environment(AuthStore())
}
