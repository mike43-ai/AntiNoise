import Foundation
import SwiftData

@MainActor
struct DataExportService {
    enum ExportError: LocalizedError {
        case writeFailed(Error)
        var errorDescription: String? {
            switch self {
            case .writeFailed(let err): return "Couldn't write export file: \(err.localizedDescription)"
            }
        }
    }

    let modelContainer: ModelContainer

    /// Assembles the export payload and writes it to a temp file.
    /// Returns the file URL — caller hands it to `UIActivityViewController`.
    func exportAll(userID: String, email: String?, now: Date = Date()) throws -> URL {
        let context = ModelContext(modelContainer)

        let captures = (try? context.fetch(FetchDescriptor<Capture>())) ?? []
        let summaries = (try? context.fetch(FetchDescriptor<Summary>())) ?? []
        let decks = (try? context.fetch(FetchDescriptor<Deck>())) ?? []
        let flashcards = (try? context.fetch(FetchDescriptor<Flashcard>())) ?? []
        // Goals are the only per-user-scoped model (others are de facto
        // single-user on-device). Filter explicitly to be safe if a future
        // multi-account test seeds cross-uid rows.
        let goalsDescriptor = FetchDescriptor<LearningGoal>(predicate: #Predicate { $0.uid == userID })
        let goals = (try? context.fetch(goalsDescriptor)) ?? []

        let payload = UserDataExportPayload(
            exportedAt: now,
            userId: userID,
            email: email,
            captures: captures.map { ExportedCapture(
                id: $0.id,
                kind: $0.kind.rawValue,
                rawText: $0.rawText,
                sourceUrl: $0.sourceURL,
                capturedAt: $0.capturedAt
            ) },
            summaries: summaries.map { ExportedSummary(
                id: $0.captureID,
                captureId: $0.captureID,
                simpleExplanation: $0.simpleExplanation,
                analogy: $0.analogy,
                knowledgeGaps: $0.knowledgeGaps,
                examples: $0.examples,
                deeperQuestion: $0.deeperQuestion,
                classification: $0.suggestedClassification.rawValue,
                generatedAt: $0.generatedAt
            ) },
            decks: decks.map { ExportedDeck(
                id: $0.id,
                summaryId: $0.sourceSummaryID,
                title: $0.title,
                createdAt: $0.createdAt
            ) },
            flashcards: flashcards.map { ExportedFlashcard(
                id: $0.id,
                deckId: $0.deckID,
                question: $0.question,
                answer: $0.answer,
                easeFactor: $0.easeFactor,
                intervalDays: $0.intervalDays,
                repetitions: $0.repetitions,
                nextReviewAt: $0.nextReviewAt,
                lastGrade: $0.lastGrade
            ) },
            goals: goals.map { ExportedGoal(
                id: $0.id,
                scope: $0.scope.rawValue,
                title: $0.title,
                createdAt: $0.createdAt
            ) }
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data: Data
        do { data = try encoder.encode(payload) }
        catch { throw ExportError.writeFailed(error) }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let stamp = formatter.string(from: now)
        let safeUID = userID.split(separator: "/").last.map(String.init) ?? "user"
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("anti-noise-export-\(safeUID)-\(stamp).json")

        do { try data.write(to: url, options: .atomic) }
        catch { throw ExportError.writeFailed(error) }
        return url
    }
}
