import AuthenticationServices
import CryptoKit
import FirebaseAuth
import Foundation
import UIKit

// Bridges ASAuthorizationController to async/await + Firebase OAuthProvider.
// Each call generates a fresh nonce; raw nonce never persists to disk.
@MainActor
final class AppleSignInCoordinator: NSObject {
    private var continuation: CheckedContinuation<AuthDataResult, Error>?
    private var currentRawNonce: String?
    private var currentController: ASAuthorizationController?

    func signIn() async throws -> AuthDataResult {
        let rawNonce = Self.randomNonceString()
        currentRawNonce = rawNonce

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(rawNonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        currentController = controller

        return try await withCheckedThrowingContinuation { cont in
            self.continuation = cont
            controller.performRequests()
        }
    }

    // MARK: Nonce helpers (Apple sample, adapted)

    private static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length

        while remaining > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let status = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                precondition(status == errSecSuccess, "SecRandomCopyBytes failed: \(status)")
                return random
            }
            for random in randoms where remaining > 0 {
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remaining -= 1
                }
            }
        }
        return result
    }

    private static func sha256(_ input: String) -> String {
        let hashed = SHA256.hash(data: Data(input.utf8))
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleSignInCoordinator: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            continuation?.resume(throwing: AuthError.appleFailed("Unexpected credential type"))
            cleanup()
            return
        }
        guard let rawNonce = currentRawNonce else {
            continuation?.resume(throwing: AuthError.appleFailed("Missing nonce"))
            cleanup()
            return
        }
        guard let idTokenData = credential.identityToken,
              let idToken = String(data: idTokenData, encoding: .utf8) else {
            continuation?.resume(throwing: AuthError.missingIDToken)
            cleanup()
            return
        }

        let fullName = credential.fullName
        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: idToken,
            rawNonce: rawNonce,
            fullName: fullName
        )

        Auth.auth().signIn(with: firebaseCredential) { [weak self] result, error in
            if let error {
                self?.continuation?.resume(throwing: AuthError(error))
            } else if let result {
                self?.continuation?.resume(returning: result)
            } else {
                self?.continuation?.resume(throwing: AuthError.appleFailed("Empty Firebase response"))
            }
            self?.cleanup()
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let mapped: AuthError = {
            if let asError = error as? ASAuthorizationError, asError.code == .canceled {
                return .appleCancelled
            }
            return .appleFailed(error.localizedDescription)
        }()
        continuation?.resume(throwing: mapped)
        cleanup()
    }

    private func cleanup() {
        continuation = nil
        currentRawNonce = nil
        currentController = nil
    }
}

// MARK: - Presentation context

extension AppleSignInCoordinator: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow }) ?? ASPresentationAnchor()
    }
}
