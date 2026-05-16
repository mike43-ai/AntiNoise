import Foundation
import SwiftData

// TODO(swift6): Capture is implicitly non-Sendable; route all mutations through
// CaptureRepository on @MainActor when migrating to strict concurrency.
@Model
final class Capture {
    @Attribute(.unique) var id: UUID
    var kindRaw: String
    var statusRaw: String
    var capturedAt: Date

    var rawText: String?
    var sourceURL: String?
    /// Filename inside `AppGroup.queueBlobsDirectory`. Resolve via `resolvedImageURL`.
    var imageFilename: String?

    /// SummarizerService writes this. JSON-encoded `FeynmanSummaryPayload` (Phase 06).
    var summaryJSON: String?

    /// Counts terminal AI failures, NOT in-attempt retries.
    var retryCount: Int

    var lastError: String?

    // Phase 07 fields (SwiftData adds these as optional/zero-default on existing stores).
    /// User-pinned classification — takes precedence over `summary.suggestedClassification`.
    var userClassificationRaw: String?
    /// Times the user has dismissed/skipped this in the daily queue. Lowers priority score.
    var skipCount: Int = 0
    /// Set when the user marks the capture "done" in the daily queue.
    var completedAt: Date?
    /// User-archived captures hide from inbox/queue but stay on disk.
    var archivedAt: Date?

    init(
        id: UUID = UUID(),
        kind: CaptureKind,
        status: CaptureStatus = .queued,
        capturedAt: Date = Date(),
        rawText: String? = nil,
        sourceURL: String? = nil,
        imageFilename: String? = nil
    ) {
        self.id = id
        self.kindRaw = kind.rawValue
        self.statusRaw = status.rawValue
        self.capturedAt = capturedAt
        self.rawText = rawText
        self.sourceURL = sourceURL
        self.imageFilename = imageFilename
        self.summaryJSON = nil
        self.retryCount = 0
        self.lastError = nil
        self.userClassificationRaw = nil
        self.skipCount = 0
        self.completedAt = nil
        self.archivedAt = nil
    }

    var kind: CaptureKind {
        CaptureKind(rawValue: kindRaw) ?? .text
    }

    var status: CaptureStatus {
        get { CaptureStatus(rawValue: statusRaw) ?? .queued }
        set { statusRaw = newValue.rawValue }
    }

    var resolvedImageURL: URL? {
        imageFilename.flatMap { SharedQueueStore.resolveBlobURL(filename: $0) }
    }

    var userClassification: ClassificationScope? {
        userClassificationRaw.flatMap { ClassificationScope(rawValue: $0) }
    }
}
