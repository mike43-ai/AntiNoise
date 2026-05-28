import FirebaseAuth
import Foundation

// Calls the Anti Noise v1.0.1 Cloudflare Workers backend with a Firebase ID
// token and an optional `x-an-tier` header. Replaces the v1.0 BYOK OpenAIClient
// — users no longer paste their own key; the operator's Gemini key lives in
// Cloudflare's encrypted secret store.
struct AIClient: Sendable {
    enum ClientError: LocalizedError {
        case notAuthenticated
        case tokenFetchFailed(Error)
        case http(status: Int, body: String?)
        case decode(Error)
        case transport(Error)
        case emptyResponse
        case rateLimited(resetAt: Date?)
        case aiUnavailable(detail: String?)

        var errorDescription: String? {
            switch self {
            case .notAuthenticated:
                return "Sign in to use AI features."
            case .tokenFetchFailed(let err):
                return "Couldn't get a session token: \(err.localizedDescription)"
            case .http(let status, _):
                return "AI service returned HTTP \(status)."
            case .decode(let err):
                return "Couldn't read AI response: \(err.localizedDescription)"
            case .transport(let err):
                return "Network error: \(err.localizedDescription)"
            case .emptyResponse:
                return "AI returned an empty response."
            case .rateLimited:
                return "Monthly AI summary limit reached. Upgrade to Pro for unlimited summaries."
            case .aiUnavailable(let detail):
                return detail.map { "AI temporarily unavailable: \($0)" }
                    ?? "AI temporarily unavailable. Try again in a moment."
            }
        }

        var isTransient: Bool {
            switch self {
            case .transport:              return true
            case .aiUnavailable:          return true
            case .http(let status, _):    return status >= 500
            default:                      return false
            }
        }
    }

    static let defaultBaseURL = URL(string: "https://anti-noise-api.huynguyenvan090.workers.dev")!

    let session: URLSession
    let baseURL: URL
    let isProProvider: @MainActor @Sendable () -> Bool

    init(
        session: URLSession = .shared,
        baseURL: URL = AIClient.defaultBaseURL,
        isProProvider: @escaping @MainActor @Sendable () -> Bool = { false }
    ) {
        self.session = session
        self.baseURL = baseURL
        self.isProProvider = isProProvider
    }

    func summarize(text: String, sourceURL: String?) async throws -> FeynmanSummaryPayload {
        let body = AIRequestBody(text: text, sourceUrl: sourceURL)
        let response: SummarizeResponse = try await performRequest(path: "/v1/ai/summarize", body: body)
        return response.payload
    }

    func generateFlashcards(text: String) async throws -> [FlashcardItem] {
        let body = AIRequestBody(text: text, sourceUrl: nil)
        let response: FlashcardsResponse = try await performRequest(path: "/v1/ai/flashcards", body: body)
        return response.cards
    }

    // MARK: - Internals

    private func performRequest<T: Decodable>(path: String, body: AIRequestBody) async throws -> T {
        let token = try await fetchIDToken()
        let isPro = await MainActor.run { isProProvider() }

        var urlRequest = URLRequest(url: baseURL.appendingPathComponent(path))
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = 60
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue(isPro ? "pro" : "free", forHTTPHeaderField: "x-an-tier")

        do {
            urlRequest.httpBody = try JSONEncoder().encode(body)
        } catch {
            throw ClientError.decode(error)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            throw ClientError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw ClientError.emptyResponse
        }

        if http.statusCode == 429 {
            let resetMs = (http.value(forHTTPHeaderField: "x-rate-reset")).flatMap(Double.init)
            let resetAt = resetMs.map { Date(timeIntervalSince1970: $0 / 1000) }
            throw ClientError.rateLimited(resetAt: resetAt)
        }

        if http.statusCode == 502 {
            let detail = decodeError(data)?.detail
            throw ClientError.aiUnavailable(detail: detail)
        }

        guard (200..<300).contains(http.statusCode) else {
            throw ClientError.http(status: http.statusCode, body: String(data: data, encoding: .utf8))
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw ClientError.decode(error)
        }
    }

    private func fetchIDToken() async throws -> String {
        guard let user = await MainActor.run(body: { Auth.auth().currentUser }) else {
            throw ClientError.notAuthenticated
        }
        do {
            return try await user.getIDToken()
        } catch {
            throw ClientError.tokenFetchFailed(error)
        }
    }

    private func decodeError(_ data: Data) -> ErrorEnvelope? {
        try? JSONDecoder().decode(ErrorEnvelope.self, from: data)
    }
}

// MARK: - Wire shapes

private struct AIRequestBody: Encodable, Sendable {
    let text: String
    let sourceUrl: String?
}

private struct SummarizeResponse: Decodable, Sendable {
    let payload: FeynmanSummaryPayload
    let model: String
}

private struct FlashcardsResponse: Decodable, Sendable {
    let cards: [FlashcardItem]
    let model: String
}

private struct ErrorEnvelope: Decodable, Sendable {
    let error: String
    let detail: String?
}
