import FirebaseFirestore
import Foundation

/// Best-effort mirror of the user's ranking signals to Firestore `users/{uid}`
/// so the backend daily-article ranker (Cloudflare Worker) can read them.
/// Local `OnboardingStore` (UserDefaults) stays the source of truth — a sync
/// failure must NOT block onboarding or any user action.
@MainActor
enum UserProfileSyncService {
    static func syncSignals(uid: String) async {
        // Cleared optionals must propagate as deletes so the backend ranker never
        // reads a stale signal the user removed (merge:true would otherwise keep it).
        var payload: [String: Any] = [
            "role": OnboardingStore.role(uid: uid)?.rawValue ?? FieldValue.delete(),
            "level": OnboardingStore.experienceLevel(uid: uid)?.rawValue ?? FieldValue.delete(),
            "goal": OnboardingStore.goal(uid: uid)?.rawValue ?? FieldValue.delete(),
        ]

        let packs = OnboardingStore.topicPacks(uid: uid)
        if !packs.isEmpty { payload["topicPacks"] = packs.map(\.rawValue).sorted() }

        do {
            try await Firestore.firestore()
                .collection("users")
                .document(uid)
                .setData(payload, merge: true)
        } catch {
            // Non-fatal: local is authoritative; the ranker falls back to generic
            // ordering when signals are absent.
            print("[AntiNoise] UserProfileSyncService.syncSignals failed: \(error)")
        }
    }
}
