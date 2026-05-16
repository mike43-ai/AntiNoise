import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class FocusSetupModel {
    static let defaultDurationsMinutes: [Int] = [15, 25, 45]

    var durationMinutes: Int = 25
    var customMinutes: Int = 25
    var useCustom: Bool = false
    var pickedDeckID: UUID?
    var pickedDeckTitle: String?
    var decks: [Deck] = []

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadDecks() {
        let descriptor = FetchDescriptor<Deck>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        decks = (try? modelContext.fetch(descriptor)) ?? []
    }

    var resolvedDurationSeconds: Int {
        let minutes = useCustom ? max(1, customMinutes) : durationMinutes
        return minutes * 60
    }

    var resolvedTargetKind: FocusTargetKind { pickedDeckID == nil ? .none : .deck }
    var resolvedTargetID: UUID? { pickedDeckID }
    var resolvedTargetLabel: String? { pickedDeckTitle }
}
