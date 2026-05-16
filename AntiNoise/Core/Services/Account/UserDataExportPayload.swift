import Foundation

// Explicit whitelist — fields are hand-picked, no auth tokens or internal
// flags. JSON schema must match phase-10 plan exactly so users can round-trip.
struct UserDataExportPayload: Codable, Sendable {
    let exportedAt: Date
    let userId: String
    let email: String?
    let captures: [ExportedCapture]
    let summaries: [ExportedSummary]
    let decks: [ExportedDeck]
    let flashcards: [ExportedFlashcard]
    let goals: [ExportedGoal]
}

struct ExportedCapture: Codable, Sendable {
    let id: UUID
    let kind: String
    let rawText: String?
    let sourceUrl: String?
    let capturedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, kind, rawText, sourceUrl = "sourceUrl", capturedAt
    }
}

struct ExportedSummary: Codable, Sendable {
    let id: UUID
    let captureId: UUID
    let simpleExplanation: String
    let analogy: String
    let knowledgeGaps: [String]
    let examples: [String]
    let deeperQuestion: String
    let classification: String
    let generatedAt: Date
}

struct ExportedDeck: Codable, Sendable {
    let id: UUID
    let summaryId: UUID?
    let title: String
    let createdAt: Date
}

struct ExportedFlashcard: Codable, Sendable {
    let id: UUID
    let deckId: UUID
    let question: String
    let answer: String
    let easeFactor: Double
    let intervalDays: Int
    let repetitions: Int
    let nextReviewAt: Date
    let lastGrade: Int?
}

struct ExportedGoal: Codable, Sendable {
    let id: UUID
    let scope: String
    let title: String
    let createdAt: Date
}
