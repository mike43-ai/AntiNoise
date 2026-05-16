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

    /// 0..n retry attempts. Used by Phase 06 for exponential backoff.
    var retryCount: Int

    var lastError: String?

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
}
