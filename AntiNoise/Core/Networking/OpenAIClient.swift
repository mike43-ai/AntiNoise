import Foundation

// Minimal OpenAI Chat Completions client. Non-streaming for MVP; SSE
// streaming is deferred to v1.1 (progressive rendering of strict-JSON
// responses is fiddly — accumulate is the simpler path).
struct OpenAIClient: Sendable {
    enum ClientError: LocalizedError {
        case missingAPIKey
        case http(status: Int, body: String?)
        case decode(Error)
        case transport(Error)
        case emptyResponse

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:        return "OpenAI API key is missing. Add it in Profile → Settings."
            case .http(let status, _):  return "OpenAI returned HTTP \(status)."
            case .decode(let err):      return "Couldn't read OpenAI response: \(err.localizedDescription)"
            case .transport(let err):   return "Network error: \(err.localizedDescription)"
            case .emptyResponse:        return "OpenAI returned an empty response."
            }
        }

        var isTransient: Bool {
            switch self {
            case .transport:              return true
            case .http(let status, _):    return status >= 500 || status == 429
            default:                      return false
            }
        }
    }

    let session: URLSession
    let endpoint: URL

    init(
        session: URLSession = .shared,
        endpoint: URL = URL(string: "https://api.openai.com/v1/chat/completions")!
    ) {
        self.session = session
        self.endpoint = endpoint
    }

    func complete(request body: ChatCompletionRequest) async throws -> String {
        guard let apiKey = SecretStore.get(forKey: SecretStore.openAIAPIKey), !apiKey.isEmpty else {
            throw ClientError.missingAPIKey
        }

        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = 60
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        // No global keyEncodingStrategy — `additionalProperties` inside the
        // JSON Schema MUST stay camelCase. Every type that needs snake_case
        // declares explicit CodingKeys.
        let encoder = JSONEncoder()
        do {
            urlRequest.httpBody = try encoder.encode(body)
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
        guard (200..<300).contains(http.statusCode) else {
            throw ClientError.http(status: http.statusCode, body: String(data: data, encoding: .utf8))
        }

        let decoder = JSONDecoder()
        do {
            let envelope = try decoder.decode(ChatCompletionResponse.self, from: data)
            guard let content = envelope.choices.first?.message.content else {
                throw ClientError.emptyResponse
            }
            return content
        } catch let err as ClientError {
            throw err
        } catch {
            throw ClientError.decode(error)
        }
    }
}

// MARK: - Request / response shapes

struct ChatCompletionRequest: Encodable, Sendable {
    let model: String
    let messages: [ChatMessage]
    let responseFormat: ResponseFormat?
    let temperature: Double?
    let maxTokens: Int?

    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case responseFormat = "response_format"
        case maxTokens      = "max_tokens"
    }
}

struct ChatMessage: Encodable, Sendable {
    let role: String
    let content: [ChatContentPart]
}

enum ChatContentPart: Encodable, Sendable {
    case text(String)
    case imageURL(String)

    enum CodingKeys: String, CodingKey { case type, text, imageURL = "image_url" }
    enum ImageContainer: CodingKey { case url }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let value):
            try container.encode("text", forKey: .type)
            try container.encode(value, forKey: .text)
        case .imageURL(let value):
            try container.encode("image_url", forKey: .type)
            var image = container.nestedContainer(keyedBy: ImageContainer.self, forKey: .imageURL)
            try image.encode(value, forKey: .url)
        }
    }
}

struct ResponseFormat: Encodable, Sendable {
    let type: String
    let jsonSchema: JSONSchemaWrapper?

    enum CodingKeys: String, CodingKey {
        case type
        case jsonSchema = "json_schema"
    }
}

struct JSONSchemaWrapper: Encodable, Sendable {
    let name: String
    let strict: Bool
    let schema: AnyEncodable
}

struct ChatCompletionResponse: Decodable, Sendable {
    struct Choice: Decodable, Sendable {
        struct Message: Decodable, Sendable {
            let content: String?
        }
        let message: Message
    }
    let choices: [Choice]
}

// Tiny type-erased Encodable so we can pass our pre-built JSON object literal
// for the response schema without a generic parameter on the request.
struct AnyEncodable: Encodable, Sendable {
    private let encodeFn: @Sendable (Encoder) throws -> Void

    init<T: Encodable & Sendable>(_ value: T) {
        self.encodeFn = { encoder in try value.encode(to: encoder) }
    }

    func encode(to encoder: Encoder) throws {
        try encodeFn(encoder)
    }
}
