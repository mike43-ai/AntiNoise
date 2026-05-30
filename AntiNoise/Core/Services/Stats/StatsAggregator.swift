import Foundation
import SwiftData

struct DashboardStats: Sendable {
    var capturesToday: Int = 0
    var capturesTotal: Int = 0
    var summariesTotal: Int = 0
    var dueCardsCount: Int = 0
    var streakDays: Int = 0
    var scopeBreakdown: [ClassificationScope: Int] = [:]
}

@MainActor
struct StatsAggregator {
    let modelContainer: ModelContainer
    // Streak now counts days with ≥1 completed card review (StreakEngine), not
    // Focus sessions. The provider supplies the same uid the review side writes
    // under, so the displayed count matches the recorded one.
    var uidProvider: () -> String? = { nil }

    func compute(now: Date = Date(), calendar: Calendar = .current) -> DashboardStats {
        let context = ModelContext(modelContainer)
        var stats = DashboardStats()

        let startOfToday = calendar.startOfDay(for: now)
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? now

        // Captures
        let capturesDescriptor = FetchDescriptor<Capture>(predicate: #Predicate { $0.archivedAt == nil })
        let captures = (try? context.fetch(capturesDescriptor)) ?? []
        stats.capturesTotal = captures.count
        stats.capturesToday = captures.filter { $0.capturedAt >= startOfToday && $0.capturedAt < endOfToday }.count

        // Summaries
        let summaryCount = (try? context.fetchCount(FetchDescriptor<Summary>())) ?? 0
        stats.summariesTotal = summaryCount

        // Due cards (today and earlier)
        let dueCountDescriptor = FetchDescriptor<Flashcard>(predicate: #Predicate { $0.nextReviewAt < endOfToday })
        stats.dueCardsCount = (try? context.fetchCount(dueCountDescriptor)) ?? 0

        // Review streak (days with ≥1 completed review), keyed by current uid.
        stats.streakDays = StreakEngine(uid: uidProvider()).currentStreak(now: now)

        // Scope breakdown — count captures by resolved scope (user override > AI suggestion).
        let summaries = (try? context.fetch(FetchDescriptor<Summary>())) ?? []
        let summariesByID = Dictionary(summaries.map { ($0.captureID, $0) }, uniquingKeysWith: { first, _ in first })
        var breakdown: [ClassificationScope: Int] = [:]
        for capture in captures {
            if let scope = PriorityScorer.resolveScope(capture: capture, summary: summariesByID[capture.id]) {
                breakdown[scope, default: 0] += 1
            }
        }
        stats.scopeBreakdown = breakdown

        return stats
    }
}
