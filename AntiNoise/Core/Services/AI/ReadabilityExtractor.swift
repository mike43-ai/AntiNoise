import Foundation

// Heuristic HTML readability — no SwiftSoup dependency. We:
// 1. Fetch the URL with a desktop user agent.
// 2. Extract <title> and <meta name="description"> or og:description.
// 3. Concatenate the longest <article> or <main> block's text content.
// 4. Fallback to <body>'s text if neither block exists.
//
// Quality is "good enough for MVP." Phase 13 may upgrade to SwiftSoup or
// a server-side readability proxy.
enum ReadabilityExtractor {
    enum ExtractorError: LocalizedError {
        case badStatus(Int)
        case decodeFailed
        case empty

        var errorDescription: String? {
            switch self {
            case .badStatus(let s): return "URL responded with HTTP \(s)."
            case .decodeFailed:     return "Couldn't decode URL response."
            case .empty:            return "URL had no readable content."
            }
        }
    }

    private static let userAgent =
        "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

    static func fetchAndExtract(url: URL, session: URLSession = .shared) async throws -> String {
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15

        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw ExtractorError.badStatus(http.statusCode)
        }
        guard let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
            throw ExtractorError.decodeFailed
        }
        let extracted = extract(from: html, sourceURL: url)
        if extracted.isEmpty { throw ExtractorError.empty }
        return extracted
    }

    static func extract(from html: String, sourceURL: URL) -> String {
        var parts: [String] = []

        if let title = firstMatch(html, pattern: "(?is)<title[^>]*>(.*?)</title>") {
            parts.append("Title: " + cleanWhitespace(stripTags(decodeEntities(title))))
        }
        if let desc = metaDescription(html) {
            parts.append("Summary: " + cleanWhitespace(decodeEntities(desc)))
        }

        let bodyText = longestBlockText(html: html) ?? bodyFallback(html: html)
        if !bodyText.isEmpty {
            parts.append(bodyText)
        }

        parts.append("Source: " + sourceURL.absoluteString)
        return parts.joined(separator: "\n\n")
    }

    private static func longestBlockText(html: String) -> String? {
        let candidates = ["article", "main"]
        var best: String?
        for tag in candidates {
            let pattern = "(?is)<\(tag)[^>]*>(.*?)</\(tag)>"
            for match in allMatches(html, pattern: pattern) {
                let text = cleanWhitespace(stripTags(decodeEntities(match)))
                if best == nil || text.count > (best?.count ?? 0) {
                    best = text
                }
            }
        }
        return best?.isEmpty == true ? nil : best
    }

    private static func bodyFallback(html: String) -> String {
        guard let body = firstMatch(html, pattern: "(?is)<body[^>]*>(.*?)</body>") else {
            return cleanWhitespace(stripTags(decodeEntities(html)))
        }
        return cleanWhitespace(stripTags(decodeEntities(body)))
    }

    // Pulls a description meta tag — tries name="description",
    // property="og:description", and the same with content/name swapped.
    private static func metaDescription(_ html: String) -> String? {
        let patterns = [
            "(?i)<meta[^>]+name=[\"']description[\"'][^>]*content=[\"']([^\"']+)[\"']",
            "(?i)<meta[^>]+property=[\"']og:description[\"'][^>]*content=[\"']([^\"']+)[\"']",
            "(?i)<meta[^>]+content=[\"']([^\"']+)[\"'][^>]+name=[\"']description[\"']",
            "(?i)<meta[^>]+content=[\"']([^\"']+)[\"'][^>]+property=[\"']og:description[\"']",
        ]
        for pattern in patterns {
            if let m = firstMatch(html, pattern: pattern) {
                return m
            }
        }
        return nil
    }

    // MARK: HTML helpers

    private static func stripTags(_ s: String) -> String {
        let scripts = "(?is)<script\\b[^>]*>.*?</script>"
        let styles  = "(?is)<style\\b[^>]*>.*?</style>"
        return s
            .replacingOccurrences(of: scripts, with: " ", options: .regularExpression)
            .replacingOccurrences(of: styles, with: " ", options: .regularExpression)
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
    }

    private static func decodeEntities(_ s: String) -> String {
        var out = s
        let entities: [String: String] = [
            "&amp;": "&", "&lt;": "<", "&gt;": ">",
            "&quot;": "\"", "&#39;": "'", "&apos;": "'",
            "&nbsp;": " ", "&mdash;": "—", "&ndash;": "–",
            "&hellip;": "…", "&rsquo;": "'", "&lsquo;": "'",
            "&ldquo;": "\u{201C}", "&rdquo;": "\u{201D}",
        ]
        for (key, value) in entities {
            out = out.replacingOccurrences(of: key, with: value)
        }
        return out
    }

    private static func cleanWhitespace(_ s: String) -> String {
        s.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func firstMatch(_ s: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)),
              match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: s) else { return nil }
        return String(s[range])
    }

    private static func allMatches(_ s: String, pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return [] }
        let range = NSRange(s.startIndex..., in: s)
        return regex.matches(in: s, range: range).compactMap { match in
            guard match.numberOfRanges > 1,
                  let r = Range(match.range(at: 1), in: s) else { return nil }
            return String(s[r])
        }
    }
}
