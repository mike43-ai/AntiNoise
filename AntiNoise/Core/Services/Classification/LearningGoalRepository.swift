import Foundation
import SwiftData

@MainActor
struct LearningGoalRepository {
    static let maxPerScope = 3

    let context: ModelContext

    func goals(uid: String) -> [LearningGoal] {
        let descriptor = FetchDescriptor<LearningGoal>(
            predicate: #Predicate { $0.uid == uid },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func goals(uid: String, scope: ClassificationScope) -> [LearningGoal] {
        let raw = scope.rawValue
        let descriptor = FetchDescriptor<LearningGoal>(
            predicate: #Predicate { $0.uid == uid && $0.scopeRaw == raw },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    @discardableResult
    func add(scope: ClassificationScope, title: String, uid: String) throws -> LearningGoal? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard goals(uid: uid, scope: scope).count < Self.maxPerScope else { return nil }
        let goal = LearningGoal(scope: scope, title: trimmed, uid: uid)
        context.insert(goal)
        try context.save()
        return goal
    }

    func remove(id: UUID) throws {
        let descriptor = FetchDescriptor<LearningGoal>(predicate: #Predicate { $0.id == id })
        if let goal = (try? context.fetch(descriptor))?.first {
            context.delete(goal)
            try context.save()
        }
    }
}
