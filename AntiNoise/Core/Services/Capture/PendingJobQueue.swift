import Foundation
import SwiftData

// Re-drives `.queued` Capture rows through the SummarizerService whenever the
// reachability observer flips to online. Concurrency-bound to MainActor since
// SwiftData ModelContext is single-threaded.
@MainActor
final class PendingJobQueue {
    private let modelContainer: ModelContainer
    private let summarizer: SummarizerService
    private let maxIterationsPerDrain = 5
    private let batchSize = 20

    init(modelContainer: ModelContainer, summarizer: SummarizerService) {
        self.modelContainer = modelContainer
        self.summarizer = summarizer
    }

    func drain() async {
        var iterations = 0
        while iterations < maxIterationsPerDrain {
            let rows = fetchQueuedBatch()
            if rows.isEmpty { break }
            for id in rows {
                await summarizer.process(captureID: id)
            }
            iterations += 1
        }
    }

    private func fetchQueuedBatch() -> [UUID] {
        let context = ModelContext(modelContainer)
        var descriptor = FetchDescriptor<Capture>(
            predicate: #Predicate<Capture> { $0.statusRaw == "queued" },
            sortBy: [SortDescriptor(\.capturedAt)]
        )
        descriptor.fetchLimit = batchSize
        return (try? context.fetch(descriptor))?.map(\.id) ?? []
    }
}
