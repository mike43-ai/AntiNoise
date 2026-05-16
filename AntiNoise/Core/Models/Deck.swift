import Foundation
import SwiftData

// TODO(swift6): Deck is implicitly non-Sendable; route mutations through @MainActor repos.
@Model
final class Deck {
    @Attribute(.unique) var id: UUID
    var sourceSummaryID: UUID?  // optional — manually-created decks are allowed
    var title: String
    var scopeRaw: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        sourceSummaryID: UUID? = nil,
        title: String,
        scope: ClassificationScope? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.sourceSummaryID = sourceSummaryID
        self.title = title
        self.scopeRaw = scope?.rawValue
        self.createdAt = createdAt
    }

    var scope: ClassificationScope? {
        scopeRaw.flatMap { ClassificationScope(rawValue: $0) }
    }
}
