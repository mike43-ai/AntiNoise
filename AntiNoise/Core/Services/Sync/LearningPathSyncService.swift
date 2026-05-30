import FirebaseFirestore
import Foundation

/// Best-effort mirror of a Deep Learn path's metadata to Firestore
/// `learning_paths/{uid}/paths/{pathId}` for cross-device continuity. Local
/// SwiftData stays the source of truth; day content is regenerable on-device, so
/// only lightweight path metadata is synced. A sync failure must never block the
/// lesson flow.
@MainActor
enum LearningPathSyncService {
    static func mirror(_ path: LearningPath, uid: String) async {
        let payload: [String: Any] = [
            "deckID": path.deckID.uuidString,
            "topic": path.topic,
            "durationDays": path.durationDays,
            "currentDay": path.currentDay,
            "status": path.status,
            "startedAt": Timestamp(date: path.startedAt),
        ]
        do {
            try await Firestore.firestore()
                .collection("learning_paths")
                .document(uid)
                .collection("paths")
                .document(path.id.uuidString)
                .setData(payload, merge: true)
        } catch {
            print("[AntiNoise] LearningPathSyncService.mirror failed: \(error)")
        }
    }
}
