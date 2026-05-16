import Foundation
import SwiftData

@MainActor
final class DailyPriorityEngine {
    private let modelContainer: ModelContainer
    private let userScopesProvider: () -> Set<ClassificationScope>
    private let calendar: Calendar

    // In-memory cache keyed by `startOfDay`. Invalidated when the engine is
    // rebuilt (e.g., sign-in / scopes change).
    private var cache: [Date: [UUID]] = [:]

    init(
        modelContainer: ModelContainer,
        userScopesProvider: @escaping () -> Set<ClassificationScope>,
        calendar: Calendar = .current
    ) {
        self.modelContainer = modelContainer
        self.userScopesProvider = userScopesProvider
        self.calendar = calendar
    }

    /// Returns ordered Capture rows for today's queue. Cached per startOfDay.
    func computeQueue(for date: Date = Date(), max: Int = 5) -> [Capture] {
        let day = calendar.startOfDay(for: date)
        if let cached = cache[day] {
            return resolve(ids: cached)
        }

        let context = ModelContext(modelContainer)
        let candidates = fetchCandidates(context: context, day: day)
        guard !candidates.isEmpty else {
            cache[day] = []
            return []
        }

        let summaries = fetchSummaries(context: context)
        let scopes = userScopesProvider()
        let now = Date()

        let scored: [(capture: Capture, score: Double)] = candidates.map { capture in
            let summary = summaries[capture.id]
            return (capture, PriorityScorer.score(
                capture: capture,
                summary: summary,
                userScopes: scopes,
                now: now
            ))
        }

        let ranked = scored
            .sorted { $0.score > $1.score }
            .prefix(max)
            .map(\.capture)

        cache[day] = ranked.map(\.id)
        return ranked
    }

    func invalidate() {
        cache.removeAll()
    }

    // MARK: - Internals

    /// Captures eligible for today: summarized + not archived + not already
    /// marked done today.
    private func fetchCandidates(context: ModelContext, day: Date) -> [Capture] {
        let summarized = CaptureStatus.summarized.rawValue
        let descriptor = FetchDescriptor<Capture>(
            predicate: #Predicate<Capture> { $0.statusRaw == summarized && $0.archivedAt == nil },
            sortBy: [SortDescriptor(\.capturedAt, order: .reverse)]
        )
        let rows = (try? context.fetch(descriptor)) ?? []
        return rows.filter { capture in
            guard let completed = capture.completedAt else { return true }
            return !calendar.isDate(completed, inSameDayAs: day)
        }
    }

    private func fetchSummaries(context: ModelContext) -> [UUID: Summary] {
        let descriptor = FetchDescriptor<Summary>()
        let rows = (try? context.fetch(descriptor)) ?? []
        return Dictionary(rows.map { ($0.captureID, $0) }, uniquingKeysWith: { first, _ in first })
    }

    private func resolve(ids: [UUID]) -> [Capture] {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<Capture>(predicate: #Predicate { ids.contains($0.id) })
        let rows = (try? context.fetch(descriptor)) ?? []
        let byID = Dictionary(rows.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return ids.compactMap { byID[$0] }
    }
}
