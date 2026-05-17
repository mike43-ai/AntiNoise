import SwiftUI

@MainActor
struct SignInView: View {
    @Environment(AuthStore.self) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var error: AuthError?

    let onSwitchToSignUp: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Welcome back")
                    .appFont(.h1)
                Text("Sign in with your email to continue.")
                    .appFont(.bodySmall)
                    .foregroundStyle(Color.textMuted)
            }

            VStack(spacing: AppSpacing.md) {
                AppTextField(
                    label: "Email",
                    text: $email,
                    placeholder: "you@email.com",
                    systemImage: "envelope",
                    keyboard: .emailAddress,
                    autocapitalization: .never
                )
                AppTextField(
                    label: "Password",
                    text: $password,
                    placeholder: "••••••••",
                    systemImage: "lock",
                    isSecure: true
                )
                if let msg = error?.errorDescription {
                    Text(msg)
                        .appFont(.caption)
                        .foregroundStyle(Color.danger)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            VStack(spacing: AppSpacing.md) {
                PrimaryButton(
                    title: "Sign in",
                    isLoading: isLoading,
                    isDisabled: !isFormValid
                ) {
                    Task { await runSignIn() }
                }
                HStack(spacing: AppSpacing.xs) {
                    Text("New here?")
                        .appFont(.bodySmall)
                        .foregroundStyle(Color.textMuted)
                    GhostButton(title: "Create account", action: onSwitchToSignUp)
                }
            }

            Spacer()
        }
        .padding(.horizontal, AppSpacing.xl)
        .padding(.top, AppSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.bgPrimary.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: { Image(systemName: "xmark") }
                    .tint(Color.textPrimary)
            }
        }
    }

    private var isFormValid: Bool {
        email.contains("@") && password.count >= 8
    }

    @MainActor
    private func runSignIn() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await auth.signIn(email: email, password: password)
            dismiss()
        } catch let err as AuthError {
            error = err
        } catch {
            self.error = AuthError(error)
        }
    }
}

#Preview {
    NavigationStack {
        SignInView(onSwitchToSignUp: {})
            .environment(AuthStore())
    }
}
