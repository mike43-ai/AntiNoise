import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftData

// Soft-delete now, hard-delete after a 7-day grace. Hard-delete is triggered
// on app launch when `now > hardDeleteAt`; full server-driven cleanup (a
// Firestore TTL + Cloud Function) lands in v1.1 per Phase 10 R3.
@MainActor
struct AccountDeletionService {
    static let gracePeriodSeconds: TimeInterval = 7 * 24 * 60 * 60

    enum DeletionError: LocalizedError {
        case noCurrentUser
        case firestoreFailed(Error)
        case authDeleteFailed(Error)

        var errorDescription: String? {
            switch self {
            case .noCurrentUser:                return "No signed-in user to delete."
            case .firestoreFailed(let err):     return "Couldn't record deletion: \(err.localizedDescription)"
            case .authDeleteFailed(let err):    return "Auth delete failed: \(err.localizedDescription)"
            }
        }
    }

    let modelContainer: ModelContainer

    /// Phase-10 soft-delete. Writes `deletedAt`/`hardDeleteAt` to Firestore,
    /// signs the user out, and clears the local SwiftData store.
    func softDelete(uid: String, email: String?, now: Date = Date()) async throws {
        let firestore = Firestore.firestore()
        let hardDeleteAt = now.addingTimeInterval(Self.gracePeriodSeconds)
        var payload: [String: Any] = [
            "deletedAt": Timestamp(date: now),
            "hardDeleteAt": Timestamp(date: hardDeleteAt),
        ]
        // Omit nil — `merge: true` would otherwise overwrite an existing email with null.
        if let email { payload["email"] = email }
        do {
            try await firestore.collection("users").document(uid).setData(payload, merge: true)
        } catch {
            throw DeletionError.firestoreFailed(error)
        }
        do {
            try Auth.auth().signOut()
        } catch {
            // Sign-out failure is non-fatal — the Firestore flag is what gates grace.
            print("[AntiNoise] signOut after softDelete failed: \(error)")
        }
        clearLocalStore()
    }

    enum HardDeleteOutcome {
        case completed
        case requiresRecentLogin
        case partial(Error)
    }

    /// Called from `AntiNoiseApp.bootstrap` when the user's Firestore record
    /// has `hardDeleteAt < now`. Purges the user's Firebase records, deletes
    /// the Auth account, and resets the SwiftData store. Returns an outcome
    /// so the caller can prompt the user to re-authenticate if needed.
    @discardableResult
    func hardDelete(uid: String) async -> HardDeleteOutcome {
        let firestore = Firestore.firestore()
        // Best-effort delete of the user doc (subcollections need a Cloud
        // Function for proper recursive purge; deferred to v1.1).
        var firestoreError: Error?
        do { try await firestore.collection("users").document(uid).delete() }
        catch { firestoreError = error }

        var authError: Error?
        if let user = Auth.auth().currentUser, user.uid == uid {
            do { try await user.delete() }
            catch { authError = error }
        }

        clearLocalStore()

        if let authError {
            let ns = authError as NSError
            if ns.domain == AuthErrorDomain,
               ns.code == AuthErrorCode.requiresRecentLogin.rawValue {
                return .requiresRecentLogin
            }
            return .partial(authError)
        }
        if let firestoreError {
            return .partial(firestoreError)
        }
        return .completed
    }

    /// Reads `users/{uid}.deletedAt` + `hardDeleteAt`. Returns the state so the
    /// caller can decide between hard-delete, restore prompt, or proceed.
    func deletionState(uid: String) async -> DeletionState {
        do {
            let snapshot = try await Firestore.firestore().collection("users").document(uid).getDocument()
            guard let data = snapshot.data(),
                  let deletedTimestamp = data["deletedAt"] as? Timestamp,
                  let hardDeleteTimestamp = data["hardDeleteAt"] as? Timestamp else {
                return .none
            }
            let now = Date()
            if hardDeleteTimestamp.dateValue() <= now {
                return .expired
            }
            return .grace(deletedAt: deletedTimestamp.dateValue(), hardDeleteAt: hardDeleteTimestamp.dateValue())
        } catch {
            return .none
        }
    }

    private func clearLocalStore() {
        let context = ModelContext(modelContainer)
        for descriptor in localFetchDescriptors() {
            descriptor.execute(in: context)
        }
        try? context.save()
    }

    private func localFetchDescriptors() -> [LocalDeleteJob] {
        [
            .init(perform: { context in
                let rows = (try? context.fetch(FetchDescriptor<Capture>())) ?? []
                rows.forEach { context.delete($0) }
            }),
            .init(perform: { context in
                let rows = (try? context.fetch(FetchDescriptor<Summary>())) ?? []
                rows.forEach { context.delete($0) }
            }),
            .init(perform: { context in
                let rows = (try? context.fetch(FetchDescriptor<Deck>())) ?? []
                rows.forEach { context.delete($0) }
            }),
            .init(perform: { context in
                let rows = (try? context.fetch(FetchDescriptor<Flashcard>())) ?? []
                rows.forEach { context.delete($0) }
            }),
            .init(perform: { context in
                let rows = (try? context.fetch(FetchDescriptor<LearningGoal>())) ?? []
                rows.forEach { context.delete($0) }
            }),
            .init(perform: { context in
                let rows = (try? context.fetch(FetchDescriptor<LearningPath>())) ?? []
                rows.forEach { context.delete($0) }
            }),
            .init(perform: { context in
                let rows = (try? context.fetch(FetchDescriptor<LearningDay>())) ?? []
                rows.forEach { context.delete($0) }
            }),
        ]
    }
}

enum DeletionState: Equatable {
    case none
    case grace(deletedAt: Date, hardDeleteAt: Date)
    case expired
}

struct LocalDeleteJob {
    let perform: (ModelContext) -> Void
    func execute(in context: ModelContext) { perform(context) }
}
