import Foundation
import SwiftData

@Model
final class LearningGoal {
    @Attribute(.unique) var id: UUID
    var scopeRaw: String
    var title: String
    var createdAt: Date
    /// Owning user UID. Anonymous goals (no sign-in) use empty string.
    var uid: String

    init(
        id: UUID = UUID(),
        scope: ClassificationScope,
        title: String,
        uid: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.scopeRaw = scope.rawValue
        self.title = title
        self.uid = uid
        self.createdAt = createdAt
    }

    var scope: ClassificationScope {
        ClassificationScope(rawValue: scopeRaw) ?? .personal
    }
}
