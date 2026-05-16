import Foundation

// Monthly AI summary counter, keyed by user UID + YYYY-MM. Feeds Phase 11's
// 5/month free-tier cap and the quota-hit paywall trigger.
//
// Anonymous (no UID) usage is counted under a `_anon` bucket so dev /
// signed-out testing still works.
enum AIUsageTracker {
    private static let defaults = UserDefaults.standard

    static let freeTierMonthlyCap = 5

    static func incrementSuccessfulSummary(uid: String?) {
        let key = monthKey(uid: uid)
        let next = defaults.integer(forKey: key) + 1
        defaults.set(next, forKey: key)
    }

    static func monthlyCount(uid: String?, on date: Date = Date()) -> Int {
        defaults.integer(forKey: monthKey(uid: uid, on: date))
    }

    static func remaining(uid: String?, cap: Int = freeTierMonthlyCap, on date: Date = Date()) -> Int {
        max(0, cap - monthlyCount(uid: uid, on: date))
    }

    private static func monthKey(uid: String?, on date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM"
        let bucket = formatter.string(from: date)
        let identity = (uid?.isEmpty == false ? uid! : "_anon")
        return "ai.usage.\(identity).\(bucket)"
    }
}
