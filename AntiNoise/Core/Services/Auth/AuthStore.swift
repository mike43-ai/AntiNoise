import Foundation
import FirebaseAuth
import Observation

enum AuthState: Equatable {
    case unknown
    case signedOut
    case signedIn(AppUser)
}

@Observable
@MainActor
final class AuthStore {
    private(set) var state: AuthState = .unknown
    var currentUser: AppUser? {
        if case .signedIn(let user) = state { return user }
        return nil
    }

    private var stateHandle: AuthStateDidChangeListenerHandle?
    private let appleCoordinator = AppleSignInCoordinator()

    func bootstrap() {
        stateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.state = user.map { .signedIn(AppUser($0)) } ?? .signedOut
            }
        }
    }

    deinit {
        if let stateHandle {
            Auth.auth().removeStateDidChangeListener(stateHandle)
        }
    }

    // MARK: Email / password

    func signUp(email: String, password: String, displayName: String?) async throws {
        try Self.validate(email: email, password: password)
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            if let displayName, !displayName.isEmpty {
                let change = result.user.createProfileChangeRequest()
                change.displayName = displayName
                try await change.commitChanges()
            }
        } catch {
            throw AuthError(error)
        }
    }

    func signIn(email: String, password: String) async throws {
        try Self.validate(email: email, password: password)
        do {
            _ = try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            throw AuthError(error)
        }
    }

    // MARK: Apple

    func signInWithApple() async throws {
        _ = try await appleCoordinator.signIn()
    }

    // MARK: Session

    func signOut() throws {
        do {
            try Auth.auth().signOut()
        } catch {
            throw AuthError(error)
        }
    }

    // MARK: Delete (stub; full flow in Phase 10)

    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else { return }
        do {
            try await user.delete()
        } catch {
            throw AuthError(error)
        }
    }

    // MARK: Validation

    private static func validate(email: String, password: String) throws {
        let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        guard email.range(of: emailRegex, options: .regularExpression) != nil else {
            throw AuthError.invalidEmail
        }
        guard password.count >= 8 else {
            throw AuthError.weakPassword
        }
    }
}
