import Foundation
import SwiftData

// TODO(swift6): Summary is implicitly non-Sendable; mutate via @MainActor.
@Model
final class Summary {
    @Attribute(.unique) var captureID: UUID
    var simpleExplanation: String
    var analogy: String
    var knowledgeGapsJSON: String  // JSON array of strings
    var examplesJSON: String       // JSON array of strings
    var deeperQuestion: String
    var suggestedClassificationRaw: String
    var recommendDeepDive: Bool
    var generatedAt: Date

    init(
        captureID: UUID,
        payload: FeynmanSummaryPayload,
        generatedAt: Date = Date()
    ) {
        self.captureID = captureID
        self.simpleExplanation = payload.simpleExplanation
        self.analogy = payload.analogy
        self.deeperQuestion = payload.deeperQuestion
        self.suggestedClassificationRaw = payload.suggestedClassification.rawValue
        self.recommendDeepDive = payload.recommendDeepDive
        self.generatedAt = generatedAt
        let encoder = JSONEncoder()
        self.knowledgeGapsJSON = (try? encoder.encode(payload.knowledgeGaps))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        self.examplesJSON = (try? encoder.encode(payload.examples))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
    }

    var knowledgeGaps: [String] {
        decodeStringArray(knowledgeGapsJSON)
    }

    var examples: [String] {
        decodeStringArray(examplesJSON)
    }

    var suggestedClassification: ClassificationScope {
        ClassificationScope(rawValue: suggestedClassificationRaw) ?? .personal
    }

    private func decodeStringArray(_ raw: String) -> [String] {
        guard let data = raw.data(using: .utf8),
              let arr = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return arr
    }
}
