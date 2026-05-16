import Foundation

// On-the-wire shape returned by GPT-4o with response_format = json_schema(strict).
// Must stay in sync with the schema in FeynmanPrompt.swift.
struct FeynmanSummaryPayload: Codable, Equatable, Sendable {
    let simpleExplanation: String
    let analogy: String
    let knowledgeGaps: [String]
    let examples: [String]
    let deeperQuestion: String
    let suggestedClassification: ClassificationScope
    let recommendDeepDive: Bool

    enum CodingKeys: String, CodingKey {
        case simpleExplanation       = "simple_explanation"
        case analogy
        case knowledgeGaps           = "knowledge_gaps"
        case examples
        case deeperQuestion          = "deeper_question"
        case suggestedClassification = "suggested_classification"
        case recommendDeepDive       = "recommend_deep_dive"
    }
}
