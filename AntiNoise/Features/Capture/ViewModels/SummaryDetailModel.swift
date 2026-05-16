import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class SummaryDetailModel {
    var capture: Capture?
    var summary: Summary?
    var isRetrying = false
    var isGeneratingDeck = false
    var generatedDeckID: UUID?
    var deckError: String?

    private let captureID: UUID
    private let modelContext: ModelContext
    private let summarizerProvider: () -> SummarizerService
    private let cardGenerator: CardGenerator

    init(
        captureID: UUID,
        modelContext: ModelContext,
        summarizerProvider: @escaping () -> SummarizerService,
        cardGenerator: CardGenerator? = nil
    ) {
        self.captureID = captureID
        self.modelContext = modelContext
        self.summarizerProvider = summarizerProvider
        self.cardGenerator = cardGenerator ?? CardGenerator(
            modelContainer: modelContext.container,
            isOnline: { true }
        )
    }

    func load() {
        capture = fetchCapture()
        summary = fetchSummary()
    }

    var effectiveScope: ClassificationScope? {
        PriorityScorer.resolveScope(capture: capture, summary: summary)
    }

    func overrideClassification(_ scope: ClassificationScope?) {
        try? ClassificationRepository(context: modelContext)
            .setUserClassification(captureID: captureID, scope: scope)
        load()
    }

    func generateDeck() async {
        guard !isGeneratingDeck else { return }
        isGeneratingDeck = true
        deckError = nil
        defer { isGeneratingDeck = false }
        do {
            generatedDeckID = try await cardGenerator.generate(fromSummaryWithCaptureID: captureID)
        } catch {
            deckError = error.localizedDescription
        }
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
