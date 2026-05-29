import Foundation
import SwiftData

@MainActor
struct ReviewSessionEngine {
    let modelContainer: ModelContainer

    /// Cards in `deckID` whose `nextReviewAt <= now`. Layered decks review in
    /// Bloom order (layer 0→1→2); within a layer, most-overdue leads. Flat/legacy
    /// decks all share layerIndex 0, so this collapses to nextReviewAt ordering.
    func dueCards(for deckID: UUID, now: Date = Date()) -> [Flashcard] {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<Flashcard>(
            predicate: #Predicate { $0.deckID == deckID && $0.nextReviewAt <= now },
            sortBy: [SortDescriptor(\.layerIndex), SortDescriptor(\.nextReviewAt)]
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
