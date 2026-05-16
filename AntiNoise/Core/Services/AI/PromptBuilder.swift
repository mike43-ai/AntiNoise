import Foundation

// Builds the user-message content array given a normalized capture input.
enum PromptBuilder {
    static func build(systemMessage: String, normalized: NormalizedCapture, userScopes: Set<GrowthScope>) -> [ChatMessage] {
        let scopeHint = scopeHintLine(userScopes)

        var userParts: [ChatContentPart] = []

        switch normalized.payload {
        case .text(let body):
            let preamble = scopeHint.map { "\($0)\n\n" } ?? ""
            userParts.append(.text(preamble + "Source content:\n\n" + body))
        case .image(let dataURI):
            if let scopeHint {
                userParts.append(.text(scopeHint))
            }
            userParts.append(.text("Summarize the image below in the Feynman style. Return JSON only."))
            userParts.append(.imageURL(dataURI))
        }

        return [
            ChatMessage(role: "system", content: [.text(systemMessage)]),
            ChatMessage(role: "user",   content: userParts),
        ]
    }

    private static func scopeHintLine(_ scopes: Set<GrowthScope>) -> String? {
        guard !scopes.isEmpty else { return nil }
        let titles = scopes.sorted { $0.rawValue < $1.rawValue }.map(\.title)
        return "Reader cares about: \(titles.joined(separator: ", "))."
    }
}
