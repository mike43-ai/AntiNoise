import Foundation

// Builds the user-prompt text the backend forwards to Gemini Flash.
// Image-payload captures are not supported in v1.0.1 — multimodal returns
// in v1.1 once the backend exposes inline_data parts.
enum PromptBuilder {
    enum PromptError: LocalizedError {
        case imageUnsupported

        var errorDescription: String? {
            switch self {
            case .imageUnsupported:
                return "Image captures will return in v1.1 — for now, paste the text or save the URL."
            }
        }
    }

    static func userPrompt(normalized: NormalizedCapture, userScopes: Set<GrowthScope>) throws -> String {
        switch normalized.payload {
        case .text(let body):
            let scopeHint = scopeHintLine(userScopes)
            let preamble = scopeHint.map { "\($0)\n\n" } ?? ""
            return preamble + body
        case .image:
            throw PromptError.imageUnsupported
        }
    }

    private static func scopeHintLine(_ scopes: Set<GrowthScope>) -> String? {
        guard !scopes.isEmpty else { return nil }
        let titles = scopes.sorted { $0.rawValue < $1.rawValue }.map(\.title)
        return "Reader cares about: \(titles.joined(separator: ", "))."
    }
}
