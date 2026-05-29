import Foundation

// Builds what the backend's /v1/ai/summarize endpoint receives. For text or URL
// captures the result is plain text. For image captures the text is a short
// hint paired with a base64 data URI — the backend forwards both as an
// OpenAI-style multimodal user message via OpenRouter, which routes to the
// active vision-capable model.
enum PromptBuilder {
    struct Built {
        let text: String
        let imageDataUri: String?
    }

    static func build(normalized: NormalizedCapture, userScopes: Set<GrowthScope>) -> Built {
        switch normalized.payload {
        case .text(let body):
            return Built(text: prefix(userScopes) + body, imageDataUri: nil)
        case .image(let dataUri):
            let hint = "Read the visible content of the attached image and apply the Feynman shape."
            return Built(text: prefix(userScopes) + hint, imageDataUri: dataUri)
        }
    }

    private static func prefix(_ scopes: Set<GrowthScope>) -> String {
        guard !scopes.isEmpty else { return "" }
        let titles = scopes.sorted { $0.rawValue < $1.rawValue }.map(\.title)
        return "Reader cares about: \(titles.joined(separator: ", ")).\n\n"
    }
}
