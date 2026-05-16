import Foundation

// Shared identifiers used by both app + extension targets.
enum AppGroup {
    static let identifier = "group.com.antinoise.shared"

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }

    // Folder under the app group that holds queued payloads written by the share
    // extension and drained by the main app on next foreground.
    static var queueDirectory: URL? {
        guard let base = containerURL else { return nil }
        return base.appendingPathComponent("queue", isDirectory: true)
    }

    static var queueBlobsDirectory: URL? {
        queueDirectory?.appendingPathComponent("blobs", isDirectory: true)
    }

    static let darwinNotificationName = "com.antinoise.queue.updated"
}
