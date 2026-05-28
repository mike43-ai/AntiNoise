import Foundation

// On-the-wire shape returned by the v1.0.1 backend (/v1/ai/summarize), which
// constrains Gemini 2.0 Flash via responseSchema. Schema lives in
// backend/src/gemini-client.ts (FEYNMAN_RESPONSE_SCHEMA).
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
