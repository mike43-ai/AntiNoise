import Foundation
import SwiftData

// Single ModelContainer for the app target. Stored inside the App Group so
// Phase 06+ services running on background tasks can read the same store.
// Image blobs are stored as files (see AppGroup.queueBlobsDirectory) and
// referenced from Capture by filename, not embedded.
enum PersistenceContainer {
    static let shared: ModelContainer = {
        do {
            let schema = Schema([Capture.self, Summary.self, LearningGoal.self, Deck.self, Flashcard.self])
            let storeURL = storeURL()
            let config = ModelConfiguration(
                schema: schema,
                url: storeURL,
                allowsSave: true,
                cloudKitDatabase: .none
            )
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Container failure is unrecoverable for the app — there's no
            // graceful degradation that keeps captures persistent.
            fatalError("Failed to initialize SwiftData container: \(error)")
        }
    }()

    private static func storeURL() -> URL {
        if let groupURL = AppGroup.containerURL {
            return groupURL.appendingPathComponent("AntiNoise.store", isDirectory: false)
        }
        // Fallback to app sandbox (simulator without entitlement, previews).
        let fallback = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return fallback.appendingPathComponent("AntiNoise.store", isDirectory: false)
    }
}
