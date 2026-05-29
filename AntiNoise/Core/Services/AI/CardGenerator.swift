import Foundation
import SwiftData

// Generates a Deck of Flashcards from a Summary. Writes to Deck + Flashcard
// tables via the v1.0.1 AIClient backend (Firebase-auth'd Gemini Flash).
@MainActor
final class CardGenerator {
    enum GenerationError: LocalizedError {
        case notAuthenticated
        case missingSummary
        case noCardsReturned
        case clientError(String)

        var errorDescription: String? {
            switch self {
            case .notAuthenticated:        return "Sign in to generate flashcards."
            case .missingSummary:          return "Couldn't find the summary to generate cards from."
            case .noCardsReturned:         return "AI didn't return any cards. Try again."
            case .clientError(let msg):    return msg
            }
        }
    }

    private let modelContainer: ModelContainer
    private let client: AIClient
    private let isOnline: @MainActor () -> Bool

    init(
        modelContainer: ModelContainer,
        client: AIClient? = nil,
        isOnline: @escaping @MainActor () -> Bool,
        isProProvider: @escaping @MainActor @Sendable () -> Bool = { false }
    ) {
        self.modelContainer = modelContainer
        self.client = client ?? AIClient(isProProvider: isProProvider)
        self.isOnline = isOnline
    }

    /// Returns the new Deck's ID on success.
    func generate(fromSummaryWithCaptureID captureID: UUID) async throws -> UUID {
        let context = ModelContext(modelContainer)
        let summaryDescriptor = FetchDescriptor<Summary>(predicate: #Predicate { $0.captureID == captureID })
        guard let summary = (try? context.fetch(summaryDescriptor))?.first else {
            throw GenerationError.missingSummary
        }
        let captureDescriptor = FetchDescriptor<Capture>(predicate: #Predicate { $0.id == captureID })
        let capture = (try? context.fetch(captureDescriptor))?.first

        let promptText = encodeSummaryForPrompt(summary: summary, capture: capture)

        let cards: [FlashcardItem]
        do {
            let onlineSnapshot = await MainActor.run { isOnline() }
            cards = try await AIRetryEngine.runWithRetries(
                isOnline: { onlineSnapshot },
                work: { try await client.generateFlashcards(text: promptText) },
                isTransient: { error in
                    if let e = error as? AIClient.ClientError { return e.isTransient }
                    return false
                }
            )
        } catch let giveUp as AIRetryEngine.GiveUp {
            throw GenerationError.clientError(giveUp.lastError.localizedDescription)
        } catch {
            throw GenerationError.clientError(error.localizedDescription)
        }

        let clamped = clamp(cards)
        guard !clamped.isEmpty else { throw GenerationError.noCardsReturned }

        // Layered when the model returned >1 distinct Bloom layer (15-card 5/5/5);
        // thin sources come back single-layer → flat deck.
        let layered = Set(clamped.map { $0.layer ?? 0 }).count > 1

        let deck = Deck(
            sourceSummaryID: summary.captureID,
            title: deckTitle(capture: capture, summary: summary),
            scope: PriorityScorer.resolveScope(capture: capture, summary: summary),
            isLayered: layered
        )
        context.insert(deck)

        for card in clamped {
            let row = Flashcard(
                deckID: deck.id,
                question: card.question,
                answer: card.answer,
                hint: card.hint,
                difficulty: card.difficulty,
                layerIndex: max(0, min(2, card.layer ?? 0))
            )
            context.insert(row)
        }
        try context.save()
        return deck.id
    }

    // MARK: - Helpers

    private func encodeSummaryForPrompt(summary: Summary, capture: Capture?) -> String {
        var lines: [String] = []
        if let title = capture?.sourceURL ?? capture?.rawText {
            lines.append("Source: \(title)")
        }
        lines.append("Simple explanation: \(summary.simpleExplanation)")
        lines.append("Analogy: \(summary.analogy)")
        if !summary.knowledgeGaps.isEmpty {
            lines.append("Knowledge gaps:\n- " + summary.knowledgeGaps.joined(separator: "\n- "))
        }
        if !summary.examples.isEmpty {
            lines.append("Examples:\n- " + summary.examples.joined(separator: "\n- "))
        }
        lines.append("Deeper question: \(summary.deeperQuestion)")
        return lines.joined(separator: "\n\n")
    }

    private func clamp(_ cards: [FlashcardItem]) -> [FlashcardItem] {
        Array(cards.prefix(SM2Constants.maxCardsPerDeck))
    }

    private func deckTitle(capture: Capture?, summary: Summary) -> String {
        if let raw = capture?.rawText, !raw.isEmpty {
            return String(raw.prefix(60))
        }
        if let url = capture?.sourceURL, let host = URL(string: url)?.host {
            return host
        }
        return String(summary.simpleExplanation.prefix(60))
    }
}

// MARK: - Decoded payload (matches backend /v1/ai/flashcards response)

struct FlashcardItem: Codable, Sendable {
    let question: String
    let answer: String
    let hint: String?
    let difficulty: Int
    /// Bloom layer 0/1/2 (v1.1). Optional — legacy/thin responses omit it (treated as 0).
    let layer: Int?
}
