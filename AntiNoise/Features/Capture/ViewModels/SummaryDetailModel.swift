import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class SummaryDetailModel {
    var capture: Capture?
    var summary: Summary?
    var isRetrying = false

    private let captureID: UUID
    private let modelContext: ModelContext
    private let summarizerProvider: () -> SummarizerService

    init(
        captureID: UUID,
        modelContext: ModelContext,
        summarizerProvider: @escaping () -> SummarizerService
    ) {
        self.captureID = captureID
        self.modelContext = modelContext
        self.summarizerProvider = summarizerProvider
    }

    func load() {
        capture = fetchCapture()
        summary = fetchSummary()
    }

    func retry() async {
        guard !isRetrying else { return }
        isRetrying = true
        defer { isRetrying = false }

        if let capture, capture.status == .failed {
            capture.status = .queued
            capture.lastError = nil
            try? modelContext.save()
            load()
        }
        await summarizerProvider().process(captureID: captureID)
        load()
    }

    private func fetchCapture() -> Capture? {
        let id = captureID
        let descriptor = FetchDescriptor<Capture>(predicate: #Predicate { $0.id == id })
        return (try? modelContext.fetch(descriptor))?.first
    }

    private func fetchSummary() -> Summary? {
        let id = captureID
        let descriptor = FetchDescriptor<Summary>(predicate: #Predicate { $0.captureID == id })
        return (try? modelContext.fetch(descriptor))?.first
    }
}
