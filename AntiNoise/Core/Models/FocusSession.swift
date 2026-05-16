import Foundation
import SwiftData

enum FocusTargetKind: String, Codable, CaseIterable, Sendable {
    case none
    case capture
    case deck
    case scope
}

@Model
final class FocusSession {
    @Attribute(.unique) var id: UUID
    var startedAt: Date
    var endedAt: Date?
    /// Planned duration in seconds.
    var plannedDurationSeconds: Int
    var targetKindRaw: String
    /// UUID of capture or deck — interpretation depends on `targetKind`.
    var targetID: UUID?
    /// Free text when `targetKind == .scope` (`"personal"` etc.) or as user note.
    var targetLabel: String?
    /// True if the user actually completed the session (>= 90% of planned).
    var completed: Bool

    init(
        id: UUID = UUID(),
        startedAt: Date,
        plannedDurationSeconds: Int,
        targetKind: FocusTargetKind = .none,
        targetID: UUID? = nil,
        targetLabel: String? = nil
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = nil
        self.plannedDurationSeconds = plannedDurationSeconds
        self.targetKindRaw = targetKind.rawValue
        self.targetID = targetID
        self.targetLabel = targetLabel
        self.completed = false
    }

    var targetKind: FocusTargetKind {
        FocusTargetKind(rawValue: targetKindRaw) ?? .none
    }
}
