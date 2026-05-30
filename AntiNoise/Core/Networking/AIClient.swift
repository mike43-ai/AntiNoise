import FirebaseAppCheck
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
                switch detail {
                case "rate-limited":
                    return "AI is busy right now. Try again in a minute."
                case "provider-down":
                    return "AI is temporarily unavailable. Try again shortly."
                case "parse-failed":
                    return "AI returned something unexpected. Tap Try again."
                case "empty-response":
                    return "AI didn't return anything. Tap Try again."
                default:
                    return "AI temporarily unavailable. Try again in a moment."
                }
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

    func summarize(text: String, sourceURL: String?, imageDataUri: String? = nil) async throws -> FeynmanSummaryPayload {
        let body = AIRequestBody(text: text, sourceUrl: sourceURL, imageDataUri: imageDataUri)
        let response: SummarizeResponse = try await performRequest(path: "/v1/ai/summarize", body: body)
        return response.payload
    }

    func generateFlashcards(text: String) async throws -> [FlashcardItem] {
        let body = AIRequestBody(text: text, sourceUrl: nil, imageDataUri: nil)
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
        if let appCheckToken = await fetchAppCheckToken() {
            urlRequest.setValue(appCheckToken, forHTTPHeaderField: "X-Firebase-AppCheck")
        }

        do {
            urlRequest.httpBody = try JSONEncoder().encode(body)
        } catch {
            throw ClientError.decode(error)
        }

        return try await send(urlRequest)
    }

    /// Daily Knowledge refresh. POST with no body — uid is derived server-side
    /// from the Firebase token, so nothing to send.
    func refreshDailyInbox() async throws -> DailyRefreshResponse {
        let token = try await fetchIDToken()
        let isPro = await MainActor.run { isProProvider() }
        var req = URLRequest(url: baseURL.appendingPathComponent("/v1/daily/refresh"))
        req.httpMethod = "POST"
        req.timeoutInterval = 60
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue(isPro ? "pro" : "free", forHTTPHeaderField: "x-an-tier")
        if let appCheckToken = await fetchAppCheckToken() {
            req.setValue(appCheckToken, forHTTPHeaderField: "X-Firebase-AppCheck")
        }
        return try await send(req)
    }

    /// Deep Learn — create a 7-day course: backend returns the outline + Day 1
    /// content in one call. Pro-only server-side (free token → 403 → .http(403)).
    func startLearningPath(
        topic: String,
        deckTitle: String?,
        captureSnippets: [String],
        role: String?,
        level: String?
    ) async throws -> LearnPathResponse {
        let body = LearnPathBody(topic: topic, deckTitle: deckTitle, captureSnippets: captureSnippets, role: role, level: level)
        return try await performLearnRequest(path: "/v1/learn/path", body: body)
    }

    /// Deep Learn — lazily expand one later day of an active course.
    func expandLearningDay(
        topic: String,
        dayIndex: Int,
        subtopic: String,
        objective: String,
        priorSubtopics: [String]
    ) async throws -> LearnDayResponse {
        let body = LearnDayBody(topic: topic, dayIndex: dayIndex, subtopic: subtopic, objective: objective, priorSubtopics: priorSubtopics)
        return try await performLearnRequest(path: "/v1/learn/day", body: body)
    }

    private func performLearnRequest<B: Encodable, T: Decodable>(path: String, body: B) async throws -> T {
        let token = try await fetchIDToken()
        let isPro = await MainActor.run { isProProvider() }
        var req = URLRequest(url: baseURL.appendingPathComponent(path))
        req.httpMethod = "POST"
        req.timeoutInterval = 90 // path call runs two sequential model calls
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue(isPro ? "pro" : "free", forHTTPHeaderField: "x-an-tier")
        if let appCheckToken = await fetchAppCheckToken() {
            req.setValue(appCheckToken, forHTTPHeaderField: "X-Firebase-AppCheck")
        }
        do {
            req.httpBody = try JSONEncoder().encode(body)
        } catch {
            throw ClientError.decode(error)
        }
        return try await send(req)
    }

    private func send<T: Decodable>(_ urlRequest: URLRequest) async throws -> T {
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

    /// Fetch the current App Check token. Returns nil (and logs in DEBUG) on
    /// failure so a token hiccup never blocks a request while the backend runs
    /// App Check in monitor mode. Once the backend enforces App Check, a nil here
    /// surfaces as a 401 from the server, handled by the existing error path.
    private func fetchAppCheckToken() async -> String? {
        do {
            return try await AppCheck.appCheck().token(forcingRefresh: false).token
        } catch {
            #if DEBUG
            print("[AIClient] App Check token fetch failed: \(error.localizedDescription)")
            #endif
            return nil
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
    let imageDataUri: String?

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(text, forKey: .text)
        try c.encodeIfPresent(sourceUrl, forKey: .sourceUrl)
        try c.encodeIfPresent(imageDataUri, forKey: .imageDataUri)
    }

    private enum CodingKeys: String, CodingKey {
        case text, sourceUrl, imageDataUri
    }
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

// Daily Knowledge — matches backend POST /v1/daily/refresh response.
struct DailyRefreshResponse: Decodable, Sendable {
    let status: String // "ok" | "caught_up" | "no_profile"
    let items: [DailySkillDTO]
}

struct DailySkillDTO: Decodable, Sendable {
    let id: String
    let title: String
    let keyword: String
    let whyNow: String
    let coreConcept: String
    let suggestedSearch: String
    let pack: String
}

// MARK: - Deep Learn wire shapes (POST /v1/learn/path + /v1/learn/day)

private struct LearnPathBody: Encodable, Sendable {
    let topic: String
    let deckTitle: String?
    let captureSnippets: [String]
    let role: String?
    let level: String?
}

private struct LearnDayBody: Encodable, Sendable {
    let topic: String
    let dayIndex: Int
    let subtopic: String
    let objective: String
    let priorSubtopics: [String]
}

/// One expanded day's content (shared by /learn/path's `day1` and /learn/day).
struct LearnDayContent: Decodable, Sendable {
    let concept: String
    let cards: [FlashcardItem]
    let applyPrompt: String
}

struct LearnPathResponse: Decodable, Sendable {
    let outlineJSON: String
    let day1: LearnDayContent
    let model: String
}

struct LearnDayResponse: Decodable, Sendable {
    let concept: String
    let cards: [FlashcardItem]
    let applyPrompt: String
}
