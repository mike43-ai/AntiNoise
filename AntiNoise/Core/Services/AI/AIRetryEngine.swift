import Foundation

// Up to 5 attempts, exponential backoff [2, 4, 8, 16] s between attempts,
// reachability-gated. Total wait budget ≤ 30s plus per-attempt HTTP timeout.
// Aborts the retry loop if reachability flips offline mid-backoff so the
// row stays `.queued` for `PendingJobQueue` to pick up later.
enum AIRetryEngine {
    static let backoffSchedule: [TimeInterval] = [2, 4, 8, 16]
    static let maxAttempts = 5

    struct GiveUp: Error {
        let lastError: Error
    }

    /// `isOnline` is consulted before every retry; if offline, we abort the
    /// retry loop and rethrow. The caller (AISummarizer) leaves the row as
    /// `.queued` so `PendingJobQueue` picks it up on the next reachability flip.
    static func runWithRetries<T: Sendable>(
        isOnline: @Sendable () -> Bool,
        work: @Sendable () async throws -> T,
        isTransient: @Sendable (Error) -> Bool
    ) async throws -> T {
        var lastError: Error?

        for attempt in 0..<maxAttempts {
            do {
                return try await work()
            } catch {
                lastError = error
                if !isTransient(error) { throw error }
                let isLast = attempt == maxAttempts - 1
                if isLast { break }
                // Don't sleep if we'll abort due to offline anyway.
                if !isOnline() { throw error }
                let delay = backoffSchedule[attempt]
                try? await Task.sleep(for: .seconds(delay))
                if !isOnline() { throw error }
            }
        }

        if let lastError {
            throw GiveUp(lastError: lastError)
        }
        // Unreachable — maxAttempts > 0.
        throw GiveUp(lastError: NSError(domain: "AIRetryEngine", code: -1))
    }
}
