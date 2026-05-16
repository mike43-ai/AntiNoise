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

    // Test/cleanup helper. Not currently wired into sign-out.
    static func clear(uid: String) {
        ["completed", "displayName", "scopes"].forEach {
            defaults.removeObject(forKey: key($0, uid: uid))
        }
    }
}
