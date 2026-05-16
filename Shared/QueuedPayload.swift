import Foundation

// On-disk shape for items handed off from the share extension to the main app.
// Lives in App Group queue dir as a small JSON file per payload. Image bytes
// (if any) live in `blobs/` and are referenced by filename.
struct QueuedPayload: Codable, Identifiable, Sendable {
    let id: UUID
    let kind: CaptureKind
    let capturedAt: Date

    let rawText: String?
    let sourceURL: String?
    /// Filename inside `AppGroup.queueBlobsDirectory`.
    let imageFilename: String?

    init(
        id: UUID = UUID(),
        kind: CaptureKind,
        capturedAt: Date = Date(),
        rawText: String? = nil,
        sourceURL: String? = nil,
        imageFilename: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.capturedAt = capturedAt
        self.rawText = rawText
        self.sourceURL = sourceURL
        self.imageFilename = imageFilename
    }
}
