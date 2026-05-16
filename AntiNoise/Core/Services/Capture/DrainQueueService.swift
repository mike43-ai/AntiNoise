import Foundation
import SwiftData

// Reads anything the share extension dropped into the App Group queue and
// inserts SwiftData rows. Idempotent: if a row with the payload's UUID
// already exists, skip + delete the queue file anyway.
@MainActor
final class DrainQueueService {
    private let modelContainer: ModelContainer
    private let summarizer: SummarizerService
    private var darwinObserver: AnyObject?

    init(modelContainer: ModelContainer, summarizer: SummarizerService) {
        self.modelContainer = modelContainer
        self.summarizer = summarizer
    }

    func start() {
        registerDarwinObserver()
    }

    func stop() {
        unregisterDarwinObserver()
    }

    func drainNow() async {
        let payloads = SharedQueueStore.pendingPayloads()
        guard !payloads.isEmpty else { return }

        let context = ModelContext(modelContainer)
        for payload in payloads {
            await ingest(payload, context: context)
        }
        try? context.save()
    }

    private func ingest(_ payload: QueuedPayload, context: ModelContext) async {
        let payloadID = payload.id
        let descriptor = FetchDescriptor<Capture>(predicate: #Predicate { $0.id == payloadID })
        let existing = (try? context.fetch(descriptor))?.first

        if existing == nil {
            // Blobs stay in the App Group blobs dir (stable across launches).
            // `cleanupOrphanedBlobs()` deletes blobs no Capture references.
            let capture = Capture(
                id: payload.id,
                kind: payload.kind,
                status: .queued,
                capturedAt: payload.capturedAt,
                rawText: payload.rawText,
                sourceURL: payload.sourceURL,
                imageFilename: payload.imageFilename
            )
            context.insert(capture)
        }

        SharedQueueStore.remove(payloadID: payload.id)

        // Best-effort dispatch. Summarizer protocol contract requires it to
        // short-circuit if status is not `.queued`, so PendingJobQueue racing
        // here won't double-process.
        await summarizer.process(captureID: payload.id)
    }

    func cleanupOrphanedBlobs() {
        guard let blobsDir = AppGroup.queueBlobsDirectory,
              let entries = try? FileManager.default.contentsOfDirectory(at: blobsDir, includingPropertiesForKeys: nil) else { return }
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<Capture>(predicate: #Predicate { $0.imageFilename != nil })
        let referenced = Set((try? context.fetch(descriptor))?.compactMap { $0.imageFilename } ?? [])
        for url in entries where !referenced.contains(url.lastPathComponent) {
            try? FileManager.default.removeItem(at: url)
        }
    }

    // MARK: Darwin notify

    private func registerDarwinObserver() {
        let name = AppGroup.darwinNotificationName as CFString
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let observer = Unmanaged.passUnretained(self).toOpaque()
        CFNotificationCenterAddObserver(
            center,
            observer,
            { _, _, _, _, _ in
                NotificationCenter.default.post(name: .queuedPayloadAvailable, object: nil)
            },
            name,
            nil,
            .deliverImmediately
        )
        darwinObserver = NotificationCenter.default.addObserver(
            forName: .queuedPayloadAvailable,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { await self?.drainNow() }
        }
    }

    private func unregisterDarwinObserver() {
        if let observer = darwinObserver {
            NotificationCenter.default.removeObserver(observer)
            darwinObserver = nil
        }
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let pointer = Unmanaged.passUnretained(self).toOpaque()
        CFNotificationCenterRemoveEveryObserver(center, pointer)
    }
}

extension Notification.Name {
    static let queuedPayloadAvailable = Notification.Name("com.antinoise.queue.bridge")
}
