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
    /// True when cards span Bloom layers (v1.1). Drives layered display; flat/legacy
    /// decks stay false. Literal default keeps SwiftData migration safe for v1.0.
    var isLayered: Bool = false
    /// True for bundled seed/sample decks (cold-start content). Excluded from
    /// lesson quota (Phase 6) and may show a "Sample" badge.
    var isSample: Bool = false

    init(
        id: UUID = UUID(),
        sourceSummaryID: UUID? = nil,
        title: String,
        scope: ClassificationScope? = nil,
        createdAt: Date = Date(),
        isLayered: Bool = false,
        isSample: Bool = false
    ) {
        self.id = id
        self.sourceSummaryID = sourceSummaryID
        self.title = title
        self.scopeRaw = scope?.rawValue
        self.createdAt = createdAt
        self.isLayered = isLayered
        self.isSample = isSample
    }

    var scope: ClassificationScope? {
        scopeRaw.flatMap { ClassificationScope(rawValue: $0) }
    }
}
