import Foundation
import SwiftData

/// One "skill to learn in the AI era" served on a given day. Cached locally from
/// the backend /v1/daily/refresh response (the source of truth is the curated
/// taxonomy in the Worker). iOS does not read Firestore for these in v1 — the
/// refresh response is cached here and shown until the date rolls over.
@Model
final class DailySkillItem {
    @Attribute(.unique) var id: UUID
    var skillId: String // taxonomy id — used for dedupe / studied-tracking
    var title: String
    var keyword: String
    var whyNow: String
    var coreConcept: String
    var suggestedSearch: String
    var pack: String
    var date: String // yyyy-MM-dd (UTC) this item was served on
    var skipped: Bool
    /// Set after "Study this" generates a deck — lets a re-tap reopen the same
    /// deck instead of regenerating (dedupe).
    var studiedDeckID: UUID?

    init(
        id: UUID = UUID(),
        skillId: String,
        title: String,
        keyword: String,
        whyNow: String,
        coreConcept: String,
        suggestedSearch: String,
        pack: String,
        date: String,
        skipped: Bool = false,
        studiedDeckID: UUID? = nil
    ) {
        self.id = id
        self.skillId = skillId
        self.title = title
        self.keyword = keyword
        self.whyNow = whyNow
        self.coreConcept = coreConcept
        self.suggestedSearch = suggestedSearch
        self.pack = pack
        self.date = date
        self.skipped = skipped
        self.studiedDeckID = studiedDeckID
    }

    /// Text fed into the capture pipeline when the user taps "Study this".
    var studyText: String {
        "\(title)\n\n\(whyNow)\n\n\(coreConcept)"
    }
}
