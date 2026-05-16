import Foundation

// Phase 06 fills this in with an OpenAI-backed implementation. Phase 05 only
// needs the protocol so the queue layer compiles + offline retry logic can be
// written and tested end-to-end before AI lands.
protocol SummarizerService: Sendable {
    /// Runs the AI pipeline for the given capture. Implementations MUST:
    /// 1. Re-fetch the row (a new ModelContext is fine — store is shared).
    /// 2. Short-circuit if `status != .queued` to avoid double-processing
    ///    when both `DrainQueueService` and `PendingJobQueue` race.
    /// 3. Transition to `.processing` before doing any network work, then
    ///    write either `.summarized` (with `summaryJSON`) or `.failed`.
    /// 4. Increment `retryCount` and stamp `lastError` on failure.
    func process(captureID: UUID) async
}

// Default no-op so Phase 05 can wire dependencies. Phase 06 swaps for OpenAISummarizer.
struct NoopSummarizerService: SummarizerService {
    func process(captureID: UUID) async {
        // Intentional no-op. Capture stays `.queued` until Phase 06 ships.
    }
}
