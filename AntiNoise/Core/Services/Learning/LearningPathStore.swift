import Foundation
import SwiftData

/// Local CRUD for Deep Learn courses. SwiftData is the source of truth; the
/// Firestore mirror (LearningPathSyncService) is best-effort. MVP rule: at most
/// one active path at a time — `createPath` is gated by the caller checking
/// `fetchActivePath()` first.
@MainActor
struct LearningPathStore {
    let context: ModelContext

    /// Insert a new path plus its empty day rows (content filled lazily later).
    @discardableResult
    func createPath(deckID: UUID, topic: String, durationDays: Int = 7, outlineJSON: String?) -> LearningPath {
        let path = LearningPath(deckID: deckID, topic: topic, durationDays: durationDays, outlineJSON: outlineJSON)
        context.insert(path)
        for day in 1...durationDays {
            context.insert(LearningDay(pathID: path.id, dayIndex: day))
        }
        try? context.save()
        return path
    }

    func fetchActivePath() -> LearningPath? {
        let active = LearningPathStatus.active.rawValue
        let descriptor = FetchDescriptor<LearningPath>(predicate: #Predicate { $0.status == active })
        return (try? context.fetch(descriptor))?.first
    }

    func days(for pathID: UUID) -> [LearningDay] {
        let descriptor = FetchDescriptor<LearningDay>(
            predicate: #Predicate { $0.pathID == pathID },
            sortBy: [SortDescriptor(\.dayIndex)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func day(pathID: UUID, dayIndex: Int) -> LearningDay? {
        let descriptor = FetchDescriptor<LearningDay>(
            predicate: #Predicate { $0.pathID == pathID && $0.dayIndex == dayIndex }
        )
        return (try? context.fetch(descriptor))?.first
    }

    /// Fill a day with generated content + its card IDs (cards inserted by caller).
    func fillDay(pathID: UUID, dayIndex: Int, concept: String, applyPrompt: String?, cardIDs: [UUID]) {
        guard let row = day(pathID: pathID, dayIndex: dayIndex) else { return }
        row.conceptText = concept
        row.applyPrompt = applyPrompt
        row.cardIDs = cardIDs
        try? context.save()
    }

    func markDayComplete(pathID: UUID, dayIndex: Int, now: Date = Date()) {
        guard let row = day(pathID: pathID, dayIndex: dayIndex) else { return }
        row.completedAt = now
        if let path = path(id: pathID), dayIndex >= path.currentDay {
            path.currentDay = min(path.durationDays, dayIndex + 1)
        }
        try? context.save()
    }

    func markPathComplete(pathID: UUID) {
        guard let path = path(id: pathID) else { return }
        path.status = LearningPathStatus.completed.rawValue
        try? context.save()
    }

    /// Abandon a path. Generated Flashcards are intentionally KEPT in the shared
    /// SRS queue — the user already started learning them.
    func abandonPath(pathID: UUID) {
        guard let path = path(id: pathID) else { return }
        path.status = LearningPathStatus.abandoned.rawValue
        try? context.save()
    }

    func path(id: UUID) -> LearningPath? {
        let descriptor = FetchDescriptor<LearningPath>(predicate: #Predicate { $0.id == id })
        return (try? context.fetch(descriptor))?.first
    }
}
