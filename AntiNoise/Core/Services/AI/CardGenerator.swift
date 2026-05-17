import Foundation
import SwiftData

// Generates a Deck of Flashcards from a Summary. Mirrors AISummarizer style
// but writes to Deck + Flashcard tables. Reuses OpenAIClient + AIRetryEngine.
@MainActor
final class CardGenerator {
    enum GenerationError: LocalizedError {
        case missingAPIKey
        case missingSummary
        case noCardsReturned
        case clientError(String)

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:           return "OpenAI API key is missing. Add it in Profile → Settings."
            case .missingSummary:          return "Couldn't find the summary to generate cards from."
            case .noCardsReturned:         return "AI didn't return any cards. Try again."
            case .clientError(let msg):    return msg
            }
        }
    }

    private let modelContainer: ModelContainer
    private let client: OpenAIClient
    private let isOnline: @MainActor () -> Bool

    init(
        modelContainer: ModelContainer,
        client: OpenAIClient = OpenAIClient(),
        isOnline: @escaping @MainActor () -> Bool
    ) {
        self.modelContainer = modelContainer
        self.client = client
        self.isOnline = isOnline
    }

    /// Returns the new Deck's ID on success.
    func generate(fromSummaryWithCaptureID captureID: UUID) async throws -> UUID {
        guard let apiKey = SecretStore.get(forKey: SecretStore.openAIAPIKey), !apiKey.isEmpty else {
            throw GenerationError.missingAPIKey
        }

        let context = ModelContext(modelContainer)
        let summaryDescriptor = FetchDescriptor<Summary>(predicate: #Predicate { $0.captureID == captureID })
        guard let summary = (try? context.fetch(summaryDescriptor))?.first else {
            throw GenerationError.missingSummary
        }
        let captureDescriptor = FetchDescriptor<Capture>(predicate: #Predicate { $0.id == captureID })
        let capture = (try? context.fetch(captureDescriptor))?.first

        let body = buildRequest(summary: summary, capture: capture)

        let raw: String
        do {
            let onlineSnapshot = await MainActor.run { isOnline() }
            raw = try await AIRetryEngine.runWithRetries(
                isOnline: { onlineSnapshot },
                work: { try await client.complete(request: body) },
                isTransient: { error in
                    if let e = error as? OpenAIClient.ClientError { return e.isTransient }
                    return false
                }
            )
        } catch let giveUp as AIRetryEngine.GiveUp {
            throw GenerationError.clientError(giveUp.lastError.localizedDescription)
        } catch {
            throw GenerationError.clientError(error.localizedDescription)
        }

        let payload = try decodePayload(raw)
        let clamped = clamp(payload.cards)
        guard !clamped.isEmpty else { throw GenerationError.noCardsReturned }

        let deck = Deck(
            sourceSummaryID: summary.captureID,
            title: deckTitle(capture: capture, summary: summary),
            scope: PriorityScorer.resolveScope(capture: capture, summary: summary)
        )
        context.insert(deck)

        for card in clamped {
            let row = Flashcard(
                deckID: deck.id,
                question: card.question,
                answer: card.answer,
                hint: card.hint,
                difficulty: card.difficulty
            )
            context.insert(row)
        }
        try context.save()
        return deck.id
    }

    // MARK: - Helpers

    private func buildRequest(summary: Summary, capture: Capture?) -> ChatCompletionRequest {
        let payload = encodeSummaryForPrompt(summary: summary, capture: capture)
        let messages: [ChatMessage] = [
            ChatMessage(role: "system", content: [.text(CardGenerationPrompt.systemMessage)]),
            ChatMessage(role: "user",   content: [.text(payload)]),
        ]
        return ChatCompletionRequest(
            model: CardGenerationPrompt.model,
            messages: messages,
            responseFormat: CardGenerationPrompt.responseFormat(),
            temperature: 0.4,
            maxTokens: 2_500
        )
    }

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

    private func decodePayload(_ raw: String) throws -> FlashcardGenerationPayload {
        guard let data = raw.data(using: .utf8) else { throw GenerationError.noCardsReturned }
        return try JSONDecoder().decode(FlashcardGenerationPayload.self, from: data)
    }

    private func clamp(_ cards: [FlashcardItem]) -> [FlashcardItem] {
        let trimmed = Array(cards.prefix(SM2Constants.maxCardsPerDeck))
        // If model under-delivered, accept what we have but warn via deck size.
        return trimmed
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

// MARK: - Decoded payload

struct FlashcardGenerationPayload: Codable, Sendable {
    let cards: [FlashcardItem]
}

struct FlashcardItem: Codable, Sendable {
    let question: String
    let answer: String
    let hint: String?
    let difficulty: Int
}
