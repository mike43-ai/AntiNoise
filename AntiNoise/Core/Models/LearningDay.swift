import Foundation
import SwiftData

/// One day of a Deep Learn course. Heavy content (`conceptText`, `applyPrompt`,
/// cards) is generated lazily the first time the user opens the day — until then
/// the optionals are nil. Pacing is open: there is intentionally NO `unlocksAt`;
/// any day can be opened at any time.
@Model
final class LearningDay {
    @Attribute(.unique) var id: UUID
    var pathID: UUID
    var dayIndex: Int
    var conceptText: String?
    var applyPrompt: String?
    /// IDs of the Flashcards generated for this day. The cards are plain
    /// `Flashcard`s (deckID = the path's deck) so they join the shared SRS queue;
    /// this list only links which cards belong to this day for display.
    var cardIDs: [UUID] = []
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        pathID: UUID,
        dayIndex: Int,
        conceptText: String? = nil,
        applyPrompt: String? = nil,
        cardIDs: [UUID] = [],
        completedAt: Date? = nil
    ) {
        self.id = id
        self.pathID = pathID
        self.dayIndex = dayIndex
        self.conceptText = conceptText
        self.applyPrompt = applyPrompt
        self.cardIDs = cardIDs
        self.completedAt = completedAt
    }

    /// A day is "ready" once its concept content has been generated.
    var isGenerated: Bool { conceptText != nil }
    var isCompleted: Bool { completedAt != nil }
}
