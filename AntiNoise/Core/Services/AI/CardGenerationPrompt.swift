import Foundation

// Generates flashcards from a Summary via GPT-4o. Returns a JSON object
// wrapping an array because OpenAI's `json_schema strict` mode requires a
// top-level object (arrays alone aren't allowed).
enum CardGenerationPrompt {
    static let model = "gpt-4o"

    static let systemMessage = """
    You are Anti Noise — a study coach who turns Feynman summaries into \
    spaced-repetition flashcards. Follow these rules:

    1. RESPOND IN THE SAME LANGUAGE as the input summary.
    2. Decide the card count between \(SM2Constants.minCardsPerDeck) and \(SM2Constants.maxCardsPerDeck) \
       based on content density. Short single-concept summaries → 3–5 cards. \
       Dense multi-concept articles → up to 15.
    3. Each card has: question (clear, single-fact), answer (one sentence or \
       short paragraph), optional hint, difficulty (1 easy → 5 hard).
    4. Avoid trivia — every card should test a transferable concept.
    5. Output STRICTLY the JSON shape requested. No markdown. No preamble.
    """

    static func responseFormat() -> ResponseFormat {
        ResponseFormat(
            type: "json_schema",
            jsonSchema: JSONSchemaWrapper(
                name: "flashcard_deck",
                strict: true,
                schema: AnyEncodable(schemaDictionary())
            )
        )
    }

    private static func schemaDictionary() -> CardDeckSchema {
        CardDeckSchema(
            type: "object",
            additionalProperties: false,
            required: ["cards"],
            properties: CardDeckSchemaProperties(
                cards: CardDeckSchemaCardsArray(
                    type: "array",
                    description: "Between \(SM2Constants.minCardsPerDeck) and \(SM2Constants.maxCardsPerDeck) cards.",
                    items: CardItemSchema(
                        type: "object",
                        additionalProperties: false,
                        // OpenAI strict mode requires every property to be in `required`.
                        // `hint` accepts null when there's no useful hint to give.
                        required: ["question", "answer", "hint", "difficulty"],
                        properties: CardItemSchemaProperties(
                            question: CardField(type: "string", description: "Single clear question."),
                            answer: CardField(type: "string", description: "Short factual answer."),
                            hint: CardOptionalField(type: ["string", "null"], description: "Optional hint to nudge recall. Use null when no useful hint."),
                            difficulty: CardIntField(type: "integer", description: "1 easy ... 5 hard.")
                        )
                    )
                )
            )
        )
    }
}

// MARK: - Schema types (mirrors JSON Schema spec, snake-friendly enough that
// no key encoding strategy is needed).

struct CardDeckSchema: Encodable, Sendable {
    let type: String
    let additionalProperties: Bool
    let required: [String]
    let properties: CardDeckSchemaProperties
}

struct CardDeckSchemaProperties: Encodable, Sendable {
    let cards: CardDeckSchemaCardsArray
}

struct CardDeckSchemaCardsArray: Encodable, Sendable {
    let type: String
    let description: String
    let items: CardItemSchema
}

struct CardItemSchema: Encodable, Sendable {
    let type: String
    let additionalProperties: Bool
    let required: [String]
    let properties: CardItemSchemaProperties
}

struct CardItemSchemaProperties: Encodable, Sendable {
    let question: CardField
    let answer: CardField
    let hint: CardOptionalField
    let difficulty: CardIntField
}

struct CardField: Encodable, Sendable {
    let type: String
    let description: String
}

struct CardOptionalField: Encodable, Sendable {
    let type: [String]
    let description: String
}

struct CardIntField: Encodable, Sendable {
    let type: String
    let description: String
}
