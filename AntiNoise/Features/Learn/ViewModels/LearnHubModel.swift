import Foundation
import Observation
import SwiftData

enum LearnHubTab: String, CaseIterable, Identifiable {
    case today, inbox, decks

    var id: String { rawValue }
    var title: String {
        switch self {
        case .today: return "Today"
        case .inbox: return "Inbox"
        case .decks: return "Decks"
        }
    }
}

@Observable
@MainActor
final class LearnHubModel {
    var tab: LearnHubTab = .today
    var dailyQueue: [Capture] = []
    var inbox: [Capture] = []
    var summariesByID: [UUID: Summary] = [:]
    var scopeFilter: ClassificationScope?
    var dueTodayCount: Int = 0

    private let modelContext: ModelContext
    private let priorityEngine: DailyPriorityEngine
    private let reviewEngine: ReviewSessionEngine

    init(modelContext: ModelContext, priorityEngine: DailyPriorityEngine) {
        self.modelContext = modelContext
        self.priorityEngine = priorityEngine
        self.reviewEngine = ReviewSessionEngine(modelContainer: modelContext.container)
    }

    func refresh() {
        priorityEngine.invalidate()
        dailyQueue = priorityEngine.computeQueue(max: 5)
        inbox = fetchInbox()
        summariesByID = fetchSummariesByID()
        dueTodayCount = reviewEngine.dueTodayCount()
    }

    func filteredInbox() -> [Capture] {
        guard let scope = scopeFilter else { return inbox }
        return inbox.filter { capture in
            let resolved = PriorityScorer.resolveScope(capture: capture, summary: summariesByID[capture.id])
            return resolved == scope
        }
    }

    // MARK: - Actions

    func markDone(captureID: UUID) {
        try? ClassificationRepository(context: modelContext).markDone(captureID: captureID)
        refresh()
    }

    func markSkipped(captureID: UUID) {
        try? ClassificationRepository(context: modelContext).markSkipped(captureID: captureID)
        refresh()
    }

    func archive(captureID: UUID) {
        try? ClassificationRepository(context: modelContext).archive(captureID: captureID)
        refresh()
    }

    // MARK: - Fetches

    private func fetchInbox() -> [Capture] {
        let descriptor = FetchDescriptor<Capture>(
            predicate: #Predicate { $0.archivedAt == nil },
            sortBy: [SortDescriptor(\.capturedAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func fetchSummariesByID() -> [UUID: Summary] {
        let descriptor = FetchDescriptor<Summary>()
        let rows = (try? modelContext.fetch(descriptor)) ?? []
        return Dictionary(rows.map { ($0.captureID, $0) }, uniquingKeysWith: { first, _ in first })
    }
}
