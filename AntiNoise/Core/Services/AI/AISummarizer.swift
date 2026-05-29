import Foundation
import SwiftData

// Real summarizer implementation. Honors the protocol contract from Phase 05:
// 1. Re-fetch the row.
// 2. Short-circuit if status != .queued.
// 3. Transition to .processing before any network work.
// 4. Write .summarized + summaryJSON (and a Summary row) on success.
// 5. Write .failed + lastError on giving up.
final class AISummarizer: SummarizerService {
    private let modelContainer: ModelContainer
    private let client: AIClient
    private let userScopesProvider: @MainActor () -> Set<GrowthScope>
    private let uidProvider: @MainActor () -> String?
    private let isOnline: @MainActor () -> Bool
    private let isProProvider: @MainActor () -> Bool

    init(
        modelContainer: ModelContainer,
        client: AIClient? = nil,
        userScopesProvider: @escaping @MainActor () -> Set<GrowthScope>,
        uidProvider: @escaping @MainActor () -> String?,
        isOnline: @escaping @MainActor () -> Bool,
        isProProvider: @escaping @MainActor () -> Bool = { false }
    ) {
        self.modelContainer = modelContainer
        let providerCopy = isProProvider
        self.client = client ?? AIClient(isProProvider: { providerCopy() })
        self.userScopesProvider = userScopesProvider
        self.uidProvider = uidProvider
        self.isOnline = isOnline
        self.isProProvider = isProProvider
    }

    func process(captureID: UUID) async {
        let context = await MainActor.run { ModelContext(modelContainer) }

        // Claim BEFORE consuming quota so a losing race-claim doesn't burn a slot.
        guard let capture = await fetchAndClaim(captureID: captureID, in: context) else { return }
        let kind = capture.kind
        let sourceURLString = capture.sourceURL

        let (uid, isPro) = await MainActor.run { (uidProvider(), isProProvider()) }
        // Gate WITHOUT consuming. The slot is only spent after the AI call
        // succeeds (see below), so a failed call — or a user tapping Try again
        // on a transient error — never burns the user's monthly quota. The
        // backend enforces the same limit authoritatively; this is the local
        // pre-check that avoids a wasted round-trip when already at the cap.
        let quotaOk = await MainActor.run { UsageQuotaService.canConsume(.aiSummary, uid: uid, isPro: isPro) }
        guard quotaOk else {
            Telemetry.track(.quotaHit(kind: .aiSummary))
            await markFailed(captureID: captureID, kind: kind, error: "Monthly AI summary limit reached. Upgrade to Pro for unlimited summaries.", errorCode: "quota_exceeded")
            return
        }

        let startedAt = Date()

        do {
            let normalized = try await CaptureNormalizer.normalize(capture)
            let built = PromptBuilder.build(
                normalized: normalized,
                userScopes: await MainActor.run { userScopesProvider() }
            )

            // Snapshot reachability once. Trade-off: we lose live re-check
            // between retries, but avoid cross-actor hops inside the retry loop.
            let onlineSnapshot = await MainActor.run { isOnline() }
            let payload = try await AIRetryEngine.runWithRetries(
                isOnline: { onlineSnapshot },
                work: { try await client.summarize(text: built.text, sourceURL: sourceURLString, imageDataUri: built.imageDataUri) },
                isTransient: { error in
                    if let e = error as? AIClient.ClientError { return e.isTransient }
                    return false
                }
            )

            // Consume the slot only now that we have a real result.
            await MainActor.run { _ = UsageQuotaService.consume(.aiSummary, uid: uid, isPro: isPro) }
            await persist(captureID: captureID, payload: payload)
            Telemetry.track(.summarySucceeded(kind: kind, latencyMs: Int(Date().timeIntervalSince(startedAt) * 1000)))

        } catch {
            let message = friendlyMessage(for: error)
            await markFailed(captureID: captureID, kind: kind, error: message, errorCode: errorCode(for: error))
        }
    }

    private func errorCode(for error: Error) -> String {
        let underlying: Error = (error as? AIRetryEngine.GiveUp)?.lastError ?? error
        if let client = underlying as? AIClient.ClientError {
            switch client {
            case .notAuthenticated:        return "not_authenticated"
            case .tokenFetchFailed:        return "token_fetch_failed"
            case .emptyResponse:           return "empty_response"
            case .decode:                  return "decode_error"
            case .transport:               return "transport"
            case .rateLimited:             return "quota_exceeded"
            case .aiUnavailable:           return "ai_unavailable"
            case .http(let status, _):     return "http_\(status)"
            }
        }
        return "unknown"
    }

    private func friendlyMessage(for error: Error) -> String {
        let underlying: Error
        if let giveUp = error as? AIRetryEngine.GiveUp {
            underlying = giveUp.lastError
        } else {
            underlying = error
        }
        if let client = underlying as? AIClient.ClientError, case .decode = client {
            return "We couldn't read the AI's response. Tap retry to try again."
        }
        if underlying is DecodingError {
            return "We couldn't read the AI's response. Tap retry to try again."
        }
        return underlying.localizedDescription
    }

    @MainActor
    private func fetchAndClaim(captureID: UUID, in context: ModelContext) -> Capture? {
        let descriptor = FetchDescriptor<Capture>(predicate: #Predicate { $0.id == captureID })
        guard let capture = (try? context.fetch(descriptor))?.first else { return nil }
        guard capture.status == .queued else { return nil }
        capture.status = .processing
        try? context.save()
        return capture
    }

    @MainActor
    private func persist(captureID: UUID, payload: FeynmanSummaryPayload) {
        let context = ModelContext(modelContainer)
        guard let capture = fetch(captureID: captureID, in: context) else { return }

        // Replace any existing Summary row for this capture.
        let existing = FetchDescriptor<Summary>(predicate: #Predicate { $0.captureID == captureID })
        if let stale = try? context.fetch(existing).first {
            context.delete(stale)
        }
        let summary = Summary(captureID: captureID, payload: payload)
        context.insert(summary)

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        capture.summaryJSON = (try? encoder.encode(payload)).flatMap { String(data: $0, encoding: .utf8) }
        capture.status = .summarized
        capture.lastError = nil
        try? context.save()
    }

    @MainActor
    private func markFailed(captureID: UUID, kind: CaptureKind?, error: String, errorCode: String) {
        let context = ModelContext(modelContainer)
        guard let capture = fetch(captureID: captureID, in: context) else { return }
        capture.status = .failed
        capture.lastError = error
        // `retryCount` reflects how many times we've terminally failed —
        // increment only here. AIRetryEngine handles in-attempt backoff
        // separately and doesn't touch this counter.
        capture.retryCount += 1
        try? context.save()
        Telemetry.track(.summaryFailed(kind: kind ?? capture.kind, errorCode: errorCode))
    }

    @MainActor
    private func fetch(captureID: UUID, in context: ModelContext) -> Capture? {
        let descriptor = FetchDescriptor<Capture>(predicate: #Predicate { $0.id == captureID })
        return (try? context.fetch(descriptor))?.first
    }
}
