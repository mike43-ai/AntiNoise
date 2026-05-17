import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class ReviewSessionModel {
    enum SessionState: Equatable {
        case reviewing
        case finished
    }

    var queue: [Flashcard] = []
    var index: Int = 0
    var isAnswerVisible: Bool = false
    var grades: [UUID: Int] = [:]
    var state: SessionState = .reviewing

    private let deckID: UUID
    private let engine: ReviewSessionEngine
    private let uidProvider: () -> String?

    init(deckID: UUID, modelContainer: ModelContainer, uidProvider: @escaping () -> String? = { nil }) {
        self.deckID = deckID
        self.engine = ReviewSessionEngine(modelContainer: modelContainer)
        self.uidProvider = uidProvider
    }

    func start() {
        queue = engine.dueCards(for: deckID)
        index = 0
        isAnswerVisible = false
        grades = [:]
        state = queue.isEmpty ? .finished : .reviewing
    }

    var currentCard: Flashcard? {
        guard index < queue.count else { return nil }
        return queue[index]
    }

    func flipCard() {
        isAnswerVisible.toggle()
    }

    /// UI swipes map to {1, 3, 5}.
    func grade(_ value: Int) {
        guard let card = currentCard else { return }
        let clamped = max(0, min(5, value))
        engine.grade(cardID: card.id, grade: clamped)
        grades[card.id] = clamped
        if clamped < 3 {
            // Re-insert further back in the session so the user sees it again.
            queue.append(card)
        }
        index += 1
        isAnswerVisible = false
        if index >= queue.count {
            state = .finished
            StreakEngine(uid: uidProvider()).markReviewedToday()
            Telemetry.track(.reviewSessionCompleted(
                cardsReviewed: totalReviewed,
                correctCount: correctCount
            ))
        }
    }

    var totalReviewed: Int { grades.count }
    var correctCount: Int { grades.values.filter { $0 >= 3 }.count }
    var lapseCount: Int { grades.values.filter { $0 < 3 }.count }
}
