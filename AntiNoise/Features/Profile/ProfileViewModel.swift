import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class ProfileViewModel {
    var stats: DashboardStats = DashboardStats()
    var goalsCountByScope: [ClassificationScope: Int] = [:]

    private let modelContext: ModelContext
    private let aggregator: StatsAggregator
    private let goalRepo: LearningGoalRepository

    init(modelContext: ModelContext, uidProvider: @escaping () -> String? = { nil }) {
        self.modelContext = modelContext
        self.aggregator = StatsAggregator(modelContainer: modelContext.container, uidProvider: uidProvider)
        self.goalRepo = LearningGoalRepository(context: modelContext)
    }

    func refresh(uid: String) {
        stats = aggregator.compute()
        var counts: [ClassificationScope: Int] = [:]
        for scope in ClassificationScope.allCases {
            counts[scope] = goalRepo.goals(uid: uid, scope: scope).count
        }
        goalsCountByScope = counts
    }
}
