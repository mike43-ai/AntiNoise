import SwiftUI

// Hidden email sign-IN sheet — reached only via a deliberate gesture on the
// landing screen (App Review + legacy accounts). No public sign-up: new users
// use Google or Apple. Documented for reviewers in ASC_METADATA.md.
@MainActor
struct EmailSignInView: View {
    @Environment(AuthStore.self) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var error: AuthError?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                }
                Section {
                    Button {
                        Task { await signIn() }
                    } label: {
                        HStack {
                            if isLoading { ProgressView() }
                            Text("Sign in")
                        }
                    }
                    .disabled(isLoading || email.isEmpty || password.isEmpty)
                } footer: {
                    Text("Email sign-in is for existing accounts only. New here? Close this and continue with Google or Apple.")
                }
            }
            .navigationTitle("Email sign-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Sign in failed", isPresented: errorBinding, presenting: error) { _ in
                Button("OK", role: .cancel) { error = nil }
            } message: { err in
                Text(err.localizedDescription)
            }
        }
    }

    private func signIn() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await auth.signIn(email: email, password: password)
            // Auth state listener swaps the root view; dismiss for tidiness.
            dismiss()
        } catch let err as AuthError {
            error = err
        } catch {
            self.error = AuthError(error)
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { error != nil }, set: { if !$0 { error = nil } })
    }
}
