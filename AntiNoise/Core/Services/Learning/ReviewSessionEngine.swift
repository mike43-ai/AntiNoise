import Foundation
import SwiftData

@MainActor
struct ReviewSessionEngine {
    let modelContainer: ModelContainer

    /// Cards in `deckID` whose `nextReviewAt <= now`. Sorted by `nextReviewAt`
    /// ascending so the most-overdue cards lead.
    func dueCards(for deckID: UUID, now: Date = Date()) -> [Flashcard] {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<Flashcard>(
            predicate: #Predicate { $0.deckID == deckID && $0.nextReviewAt <= now },
            sortBy: [SortDescriptor(\.nextReviewAt)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Total cards due across all decks today.
    func dueTodayCount(now: Date = Date()) -> Int {
        let endOfDay = Calendar.current.startOfDay(for: now).addingTimeInterval(86_400)
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<Flashcard>(predicate: #Predicate { $0.nextReviewAt < endOfDay })
        return (try? context.fetchCount(descriptor)) ?? 0
    }

    /// Apply a grade to a card and persist. Caller passes the card's ID so
    /// we re-fetch and write in one transaction.
    func grade(cardID: UUID, grade: Int, now: Date = Date()) {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<Flashcard>(predicate: #Predicate { $0.id == cardID })
        guard let card = (try? context.fetch(descriptor))?.first else { return }
        let outcome = SpacedRepetitionScheduler.next(
            easeFactor: card.easeFactor,
            intervalDays: card.intervalDays,
            repetitions: card.repetitions,
            grade: grade,
            now: now
        )
        SpacedRepetitionScheduler.apply(outcome, to: card, grade: grade)
        try? context.save()
    }
}
