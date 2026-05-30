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
    private let googleCoordinator = GoogleSignInCoordinator()

    func bootstrap() {
        stateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.state = user.map { .signedIn(AppUser($0)) } ?? .signedOut
            }
        }
    }

    // No deinit cleanup: AuthStore is a singleton owned by App for the
    // process lifetime, so the Firebase listener never needs removal.

    // MARK: Apple

    func signInWithApple() async throws {
        let result = try await appleCoordinator.signIn()
        let isNewUser = result.additionalUserInfo?.isNewUser == true
        Telemetry.track(isNewUser ? .signUp(method: .apple) : .login(method: .apple))
    }

    // MARK: Google

    func signInWithGoogle() async throws {
        let result = try await googleCoordinator.signIn()
        let isNewUser = result.additionalUserInfo?.isNewUser == true
        Telemetry.track(isNewUser ? .signUp(method: .google) : .login(method: .google))
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
}
