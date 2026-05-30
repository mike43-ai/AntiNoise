import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class HomeViewModel {
    var stats: DashboardStats = DashboardStats()
    var queuePreview: [Capture] = []
    var summariesByID: [UUID: Summary] = [:]

    private let modelContext: ModelContext
    private let aggregator: StatsAggregator
    private let priorityEngine: DailyPriorityEngine

    init(
        modelContext: ModelContext,
        userScopesProvider: @escaping () -> Set<ClassificationScope>,
        uidProvider: @escaping () -> String? = { nil }
    ) {
        self.modelContext = modelContext
        self.aggregator = StatsAggregator(modelContainer: modelContext.container, uidProvider: uidProvider)
        self.priorityEngine = DailyPriorityEngine(
            modelContainer: modelContext.container,
            userScopesProvider: userScopesProvider
        )
    }

    func refresh() {
        priorityEngine.invalidate()
        stats = aggregator.compute()
        queuePreview = Array(priorityEngine.computeQueue(max: 3))
        summariesByID = fetchSummariesByID()
    }

    private func fetchSummariesByID() -> [UUID: Summary] {
        let descriptor = FetchDescriptor<Summary>()
        let rows = (try? modelContext.fetch(descriptor)) ?? []
        return Dictionary(rows.map { ($0.captureID, $0) }, uniquingKeysWith: { first, _ in first })
    }
}
