import Foundation
import SwiftData

/// A Deep Learn course: a multi-day mastery path generated from a deck. The
/// outline (one sub-topic + objective per day) is generated once at opt-in and
/// cached as JSON; each day's heavy content is filled lazily (see LearningDay).
/// Brand-new entity → additive, SwiftData lightweight-migration safe.
@Model
final class LearningPath {
    @Attribute(.unique) var id: UUID
    var deckID: UUID
    var topic: String
    var durationDays: Int = 7
    var startedAt: Date
    /// Highest day the user has reached (1...durationDays). Display/progress only;
    /// pacing is open, so any unfilled day can still be opened on demand.
    var currentDay: Int = 1
    /// active | completed | abandoned
    var status: String = LearningPathStatus.active.rawValue
    /// Cached 7-day outline (array of {day, subtopic, objective}) as JSON.
    var outlineJSON: String?

    init(
        id: UUID = UUID(),
        deckID: UUID,
        topic: String,
        durationDays: Int = 7,
        startedAt: Date = Date(),
        currentDay: Int = 1,
        status: LearningPathStatus = .active,
        outlineJSON: String? = nil
    ) {
        self.id = id
        self.deckID = deckID
        self.topic = topic
        self.durationDays = durationDays
        self.startedAt = startedAt
        self.currentDay = currentDay
        self.status = status.rawValue
        self.outlineJSON = outlineJSON
    }

    var statusValue: LearningPathStatus {
        LearningPathStatus(rawValue: status) ?? .active
    }
}

enum LearningPathStatus: String {
    case active
    case completed
    case abandoned
}
