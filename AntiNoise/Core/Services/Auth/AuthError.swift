import Foundation
import FirebaseAuth

enum AuthError: LocalizedError {
    case invalidEmail
    case weakPassword
    case wrongPassword
    case userNotFound
    case emailAlreadyInUse
    case networkOffline
    case appleCancelled
    case appleFailed(String)
    case missingIDToken
    case requiresReauthentication
    case revokedByUser
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidEmail:            return "That doesn't look like a valid email."
        case .weakPassword:            return "Password must be at least 8 characters."
        case .wrongPassword:           return "Email or password is incorrect."
        case .userNotFound:            return "No account found with that email."
        case .emailAlreadyInUse:       return "An account with that email already exists."
        case .networkOffline:          return "You're offline. Connect and try again."
        case .appleCancelled:          return "Sign in with Apple was cancelled."
        case .appleFailed(let msg):    return "Apple sign-in failed: \(msg)"
        case .missingIDToken:          return "Apple did not return a valid identity token."
        case .requiresReauthentication:return "Please sign in again to continue."
        case .revokedByUser:           return "Your Apple ID access was revoked. Please sign in again."
        case .unknown(let msg):        return msg
        }
    }

    init(_ error: Error) {
        let ns = error as NSError
        guard ns.domain == AuthErrorDomain, let code = AuthErrorCode.Code(rawValue: ns.code) else {
            self = .unknown(ns.localizedDescription)
            return
        }
        switch code {
        case .invalidEmail:                self = .invalidEmail
        case .weakPassword:                self = .weakPassword
        case .wrongPassword,
             .invalidCredential:           self = .wrongPassword
        case .userNotFound:                self = .userNotFound
        case .emailAlreadyInUse:           self = .emailAlreadyInUse
        case .networkError:                self = .networkOffline
        case .requiresRecentLogin:         self = .requiresReauthentication
        default:                           self = .unknown(ns.localizedDescription)
        }
    }
}
