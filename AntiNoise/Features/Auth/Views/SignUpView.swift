import SwiftUI

@MainActor
struct SignUpView: View {
    @Environment(AuthStore.self) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var error: AuthError?

    let onSwitchToSignIn: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Create your account")
                        .appFont(.h1)
                    Text("Capture, summarize, learn — in one quiet stack.")
                        .appFont(.bodySmall)
                        .foregroundStyle(Color.textMuted)
                }

                VStack(spacing: AppSpacing.md) {
                    AppTextField(
                        label: "Your name",
                        text: $displayName,
                        placeholder: "Huy",
                        systemImage: "person",
                        autocapitalization: .words
                    )
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
                        placeholder: "Minimum 8 characters",
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

                PrimaryButton(
                    title: "Create account",
                    isLoading: isLoading,
                    isDisabled: !isFormValid
                ) {
                    Task { await runSignUp() }
                }

                HStack(spacing: AppSpacing.xs) {
                    Text("Already have an account?")
                        .appFont(.bodySmall)
                        .foregroundStyle(Color.textMuted)
                    GhostButton(title: "Sign in", action: onSwitchToSignIn)
                }
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.top, AppSpacing.xl)
        }
        .background(Color.bgPrimary.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: { Image(systemName: "xmark") }
                    .tint(Color.textPrimary)
            }
        }
    }

    private var isFormValid: Bool {
        email.contains("@") && password.count >= 8 && !displayName.isEmpty
    }

    @MainActor
    private func runSignUp() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await auth.signUp(email: email, password: password, displayName: displayName)
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
        SignUpView(onSwitchToSignIn: {})
            .environment(AuthStore())
    }
}
