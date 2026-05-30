import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import UIKit

// Bridges GoogleSignIn to async/await + Firebase. Mirrors AppleSignInCoordinator.
// The Google client ID comes from FirebaseApp options (populated by
// GoogleService-Info.plist once the Google provider is enabled in Firebase).
@MainActor
final class GoogleSignInCoordinator {
    func signIn() async throws -> AuthDataResult {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthError.googleFailed("Google sign-in isn't configured. Enable the Google provider in Firebase and re-download GoogleService-Info.plist.")
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        guard let presenter = Self.topViewController() else {
            throw AuthError.googleFailed("No view controller to present from.")
        }

        let result: GIDSignInResult
        do {
            result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
        } catch {
            let ns = error as NSError
            if ns.domain == kGIDSignInErrorDomain, ns.code == GIDSignInError.canceled.rawValue {
                throw AuthError.googleCancelled
            }
            throw AuthError.googleFailed(error.localizedDescription)
        }

        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.missingIDToken
        }
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )
        do {
            return try await Auth.auth().signIn(with: credential)
        } catch {
            throw AuthError(error)
        }
    }

    // Topmost view controller to present the Google sheet from.
    private static func topViewController() -> UIViewController? {
        let root = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })?
            .rootViewController
        var top = root
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}
