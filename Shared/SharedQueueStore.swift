import Foundation

// File-backed queue that lives inside the App Group container. The share
// extension only writes; the main app drains. No SwiftData in here — the
// extension's 120 MB / ~30s budget rules out booting a ModelContainer.
enum SharedQueueStore {
    enum StoreError: LocalizedError {
        case appGroupUnavailable
        case writeFailed(Error)

        var errorDescription: String? {
            switch self {
            case .appGroupUnavailable:
                return "Anti Noise's shared storage isn't available. Reinstall the app if this persists."
            case .writeFailed(let underlying):
                return "Couldn't save the capture: \(underlying.localizedDescription)"
            }
        }
    }

    static func ensureDirectories() throws {
        guard let queueDir = AppGroup.queueDirectory,
              let blobsDir = AppGroup.queueBlobsDirectory else {
            throw StoreError.appGroupUnavailable
        }
        let fm = FileManager.default
        try fm.createDirectory(at: queueDir, withIntermediateDirectories: true)
        try fm.createDirectory(at: blobsDir, withIntermediateDirectories: true)
    }

    static func enqueue(_ payload: QueuedPayload) throws {
        try ensureDirectories()
        guard let queueDir = AppGroup.queueDirectory else {
            throw StoreError.appGroupUnavailable
        }
        let url = queueDir.appendingPathComponent("\(payload.id.uuidString).json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        do {
            let data = try encoder.encode(payload)
            try data.write(to: url, options: .atomic)
        } catch {
            throw StoreError.writeFailed(error)
        }
    }

    /// Write image bytes to the shared blobs dir, return filename to reference.
    static func writeImage(_ data: Data, suggestedExtension: String = "jpg") throws -> String {
        try ensureDirectories()
        guard let blobsDir = AppGroup.queueBlobsDirectory else {
            throw StoreError.appGroupUnavailable
        }
        let filename = "\(UUID().uuidString).\(suggestedExtension)"
        let url = blobsDir.appendingPathComponent(filename)
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw StoreError.writeFailed(error)
        }
        return filename
    }

    static func pendingPayloads() -> [QueuedPayload] {
        guard let queueDir = AppGroup.queueDirectory,
              let entries = try? FileManager.default.contentsOfDirectory(at: queueDir, includingPropertiesForKeys: nil) else {
            return []
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return entries
            .filter { $0.pathExtension == "json" }
            .compactMap { url in
                guard let data = try? Data(contentsOf: url),
                      let payload = try? decoder.decode(QueuedPayload.self, from: data) else {
                    return nil
                }
                return payload
            }
            .sorted { $0.capturedAt < $1.capturedAt }
    }

    static func remove(payloadID id: UUID) {
        guard let queueDir = AppGroup.queueDirectory else { return }
        let url = queueDir.appendingPathComponent("\(id.uuidString).json")
        try? FileManager.default.removeItem(at: url)
    }

    static func resolveBlobURL(filename: String) -> URL? {
        AppGroup.queueBlobsDirectory?.appendingPathComponent(filename)
    }

    static func postUpdateNotification() {
        let name = CFNotificationName(AppGroup.darwinNotificationName as CFString)
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            name,
            nil,
            nil,
            true
        )
    }
}
