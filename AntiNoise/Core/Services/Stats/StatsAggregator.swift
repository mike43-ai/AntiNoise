import Foundation
import SwiftData

struct DashboardStats: Sendable {
    var capturesToday: Int = 0
    var capturesTotal: Int = 0
    var summariesTotal: Int = 0
    var dueCardsCount: Int = 0
    var focusStreakDays: Int = 0
    var totalFocusMinutes: Int = 0
    var scopeBreakdown: [ClassificationScope: Int] = [:]
}

@MainActor
struct StatsAggregator {
    let modelContainer: ModelContainer

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

        // Focus sessions: total minutes + streak
        let sessions = (try? context.fetch(FetchDescriptor<FocusSession>())) ?? []
        let completedSessions = sessions.filter { $0.completed }
        stats.totalFocusMinutes = completedSessions.reduce(0) { partial, session in
            guard let endedAt = session.endedAt else { return partial }
            let seconds = Int(endedAt.timeIntervalSince(session.startedAt))
            return partial + max(0, seconds / 60)
        }
        stats.focusStreakDays = streakLength(sessions: completedSessions, today: startOfToday, calendar: calendar)

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

    private func streakLength(sessions: [FocusSession], today: Date, calendar: Calendar) -> Int {
        guard !sessions.isEmpty else { return 0 }
        let days = Set(sessions.map { calendar.startOfDay(for: $0.startedAt) })
        var streak = 0
        var cursor = today
        while days.contains(cursor) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }
}
