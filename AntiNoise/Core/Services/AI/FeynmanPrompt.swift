import Foundation

// System prompt + JSON schema that pins GPT-4o into a 5-section Feynman output.
// Keep schema mirrored with FeynmanSummaryPayload.CodingKeys.
enum FeynmanPrompt {
    static let model = "gpt-4o"

    static let systemMessage = """
    You are Anti Noise — a learning assistant that distills any source into a \
    Feynman-method summary. Follow these rules without exception:

    1. RESPOND IN THE SAME LANGUAGE as the source content. If the source is \
       Vietnamese, respond in Vietnamese. If English, English.
    2. Explain ideas at a 12-year-old reading level. No jargon. Define every \
       term you introduce.
    3. Output STRICTLY the JSON shape requested — no markdown, no preamble.
    4. simple_explanation: 2–4 short sentences capturing the core idea.
    5. analogy: one concrete analogy mapping the idea to everyday life.
    6. knowledge_gaps: 2–5 things the source assumes but doesn't explain.
    7. examples: 2–4 concrete examples that ground the idea.
    8. deeper_question: one follow-up question that pushes understanding.
    9. suggested_classification: pick the scope that best fits — personal, \
       work, or business.
    10. recommend_deep_dive: true if this would meaningfully benefit from \
        spaced-repetition study; otherwise false.
    """

    static func responseFormat() -> ResponseFormat {
        ResponseFormat(
            type: "json_schema",
            jsonSchema: JSONSchemaWrapper(
                name: "feynman_summary",
                strict: true,
                schema: AnyEncodable(schemaDictionary())
            )
        )
    }

    // Mirror of the JSON schema in phase-06 spec. Hand-rolled Dictionary
    // wrapper to avoid pulling a generic JSON library.
    private static func schemaDictionary() -> JSONSchema {
        JSONSchema(
            type: "object",
            additionalProperties: false,
            required: [
                "simple_explanation", "analogy", "knowledge_gaps",
                "examples", "deeper_question",
                "suggested_classification", "recommend_deep_dive",
            ],
            properties: [
                "simple_explanation": .string("Explain like to a 12-year-old. 2–4 sentences."),
                "analogy":            .string("One concrete analogy that maps the core idea to everyday life."),
                "knowledge_gaps":     .arrayOfString("What the source assumes but doesn't explain. 2–5 items."),
                "examples":           .arrayOfString("Concrete examples that ground the idea. 2–4 items."),
                "deeper_question":    .string("One follow-up question that pushes understanding further."),
                "suggested_classification": .enumString(["personal", "work", "business"]),
                "recommend_deep_dive":      .boolean,
            ]
        )
    }
}

// MARK: - Tiny JSON schema codec (only what we need)

struct JSONSchema: Encodable, Sendable {
    let type: String
    let additionalProperties: Bool
    let required: [String]
    let properties: [String: JSONSchemaProperty]
}

enum JSONSchemaProperty: Encodable, Sendable {
    case string(String)
    case arrayOfString(String)
    case boolean
    case enumString([String])

    enum CodingKeys: String, CodingKey { case type, description, items, enumValues = "enum" }
    enum ItemsKey: CodingKey { case type }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .string(let desc):
            try container.encode("string", forKey: .type)
            try container.encode(desc, forKey: .description)
        case .arrayOfString(let desc):
            try container.encode("array", forKey: .type)
            try container.encode(desc, forKey: .description)
            var items = container.nestedContainer(keyedBy: ItemsKey.self, forKey: .items)
            try items.encode("string", forKey: .type)
        case .boolean:
            try container.encode("boolean", forKey: .type)
        case .enumString(let values):
            try container.encode("string", forKey: .type)
            try container.encode(values, forKey: .enumValues)
        }
    }
}
