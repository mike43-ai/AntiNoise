import Foundation
import FirebaseAuth

struct AppUser: Codable, Equatable, Identifiable {
    let id: String
    let email: String?
    let displayName: String?
    let isAnonymous: Bool
    let createdAt: Date?
    let lastSignInAt: Date?

    init(_ user: User) {
        self.id = user.uid
        self.email = user.email
        self.displayName = user.displayName
        self.isAnonymous = user.isAnonymous
        self.createdAt = user.metadata.creationDate
        self.lastSignInAt = user.metadata.lastSignInDate
    }

    init(id: String, email: String?, displayName: String?, isAnonymous: Bool = false, createdAt: Date? = nil, lastSignInAt: Date? = nil) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.isAnonymous = isAnonymous
        self.createdAt = createdAt
        self.lastSignInAt = lastSignInAt
    }
}
