import Foundation
import UIKit

enum NormalizedCaptureKind: Sendable {
    case text(String)
    case image(String)   // base64 data URI
}

struct NormalizedCapture: Sendable {
    let payload: NormalizedCaptureKind
    let truncated: Bool
}

// Turns a Capture row into the content body GPT-4o receives.
enum CaptureNormalizer {
    // Conservative cap for input text. GPT-4o has a 128k context but we keep
    // prompts cheap. Charset-level cap, not token-aware.
    static let maxInputCharacters = 18_000

    enum NormalizerError: LocalizedError {
        case emptyCapture
        case urlFetchFailed(Error)
        case imageMissing

        var errorDescription: String? {
            switch self {
            case .emptyCapture:           return "Capture has no content to summarize."
            case .urlFetchFailed(let e):  return "Couldn't fetch the URL: \(e.localizedDescription)"
            case .imageMissing:           return "Image file is missing on disk."
            }
        }
    }

    static func normalize(_ capture: Capture) async throws -> NormalizedCapture {
        switch capture.kind {
        case .text:
            guard let raw = capture.rawText?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !raw.isEmpty else {
                throw NormalizerError.emptyCapture
            }
            let (text, truncated) = truncate(raw)
            return NormalizedCapture(payload: .text(text), truncated: truncated)

        case .url:
            guard let urlString = capture.sourceURL, let url = URL(string: urlString) else {
                throw NormalizerError.emptyCapture
            }
            let extracted: String
            do {
                extracted = try await ReadabilityExtractor.fetchAndExtract(url: url)
            } catch {
                throw NormalizerError.urlFetchFailed(error)
            }
            let (text, truncated) = truncate(extracted)
            return NormalizedCapture(payload: .text(text), truncated: truncated)

        case .image:
            guard let url = capture.resolvedImageURL,
                  FileManager.default.fileExists(atPath: url.path) else {
                throw NormalizerError.imageMissing
            }
            let dataURI = try await ImageEncoder.encodeAsDataURI(url: url)
            return NormalizedCapture(payload: .image(dataURI), truncated: false)
        }
    }

    private static func truncate(_ text: String) -> (String, Bool) {
        if text.count <= maxInputCharacters { return (text, false) }
        let prefix = text.prefix(maxInputCharacters)
        return (String(prefix) + "\n\n[truncated — source exceeded MVP context budget]", true)
    }
}
