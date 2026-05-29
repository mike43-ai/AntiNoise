import Foundation

// User-scoped onboarding state. AppStorage couldn't be used here because @AppStorage
// keys are evaluated once at view init; switching accounts on the same device must
// re-read fresh per-uid keys without recreating the view.
enum OnboardingStore {
    private static let defaults = UserDefaults.standard

    private static func key(_ field: String, uid: String) -> String {
        "onboarding.\(field).\(uid)"
    }

    static func isCompleted(uid: String) -> Bool {
        defaults.bool(forKey: key("completed", uid: uid))
    }

    static func setCompleted(_ value: Bool, uid: String) {
        defaults.set(value, forKey: key("completed", uid: uid))
    }

    static func displayName(uid: String) -> String {
        defaults.string(forKey: key("displayName", uid: uid)) ?? ""
    }

    static func setDisplayName(_ name: String, uid: String) {
        defaults.set(name, forKey: key("displayName", uid: uid))
    }

    static func scopes(uid: String) -> Set<GrowthScope> {
        let csv = defaults.string(forKey: key("scopes", uid: uid)) ?? ""
        let raw = csv.split(separator: ",").map(String.init)
        return Set(raw.compactMap(GrowthScope.init(rawValue:)))
    }

    static func setScopes(_ scopes: Set<GrowthScope>, uid: String) {
        let csv = scopes.map(\.rawValue).sorted().joined(separator: ",")
        defaults.set(csv, forKey: key("scopes", uid: uid))
    }

    // MARK: - Daily Knowledge signals (v1.1)

    /// Required at onboarding. Empty set means the user hasn't picked yet —
    /// used to detect existing v1.0 users who need the topic-pack backfill.
    static func topicPacks(uid: String) -> Set<TopicPack> {
        let csv = defaults.string(forKey: key("topicPacks", uid: uid)) ?? ""
        return Set(csv.split(separator: ",").map(String.init).compactMap(TopicPack.init(rawValue:)))
    }

    static func setTopicPacks(_ packs: Set<TopicPack>, uid: String) {
        let csv = packs.map(\.rawValue).sorted().joined(separator: ",")
        defaults.set(csv, forKey: key("topicPacks", uid: uid))
    }

    /// True once the user has chosen at least one topic pack. Gates the
    /// existing-user backfill prompt (v1.0 users onboarded before this existed).
    static func hasTopicPacks(uid: String) -> Bool {
        !topicPacks(uid: uid).isEmpty
    }

    // Optional ranking signals — set in Profile, not onboarding (red-team D).
    static func role(uid: String) -> UserRole? {
        defaults.string(forKey: key("role", uid: uid)).flatMap(UserRole.init(rawValue:))
    }

    static func setRole(_ role: UserRole?, uid: String) {
        defaults.set(role?.rawValue, forKey: key("role", uid: uid))
    }

    static func experienceLevel(uid: String) -> ExperienceLevel? {
        defaults.string(forKey: key("level", uid: uid)).flatMap(ExperienceLevel.init(rawValue:))
    }

    static func setExperienceLevel(_ level: ExperienceLevel?, uid: String) {
        defaults.set(level?.rawValue, forKey: key("level", uid: uid))
    }

    static func goal(uid: String) -> UserGoal? {
        defaults.string(forKey: key("goal", uid: uid)).flatMap(UserGoal.init(rawValue:))
    }

    static func setGoal(_ goal: UserGoal?, uid: String) {
        defaults.set(goal?.rawValue, forKey: key("goal", uid: uid))
    }

    // Test/cleanup helper. Not currently wired into sign-out.
    static func clear(uid: String) {
        ["completed", "displayName", "scopes", "topicPacks", "role", "level", "goal"].forEach {
            defaults.removeObject(forKey: key($0, uid: uid))
        }
    }
}
