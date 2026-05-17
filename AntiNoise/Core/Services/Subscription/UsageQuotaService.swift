import Foundation

// Free-tier counters per locked decision: 3 captures/day, 5 AI summaries/month.
// Pro skips all checks. Counters are keyed by user UID + local date, so a
// timezone-change abuse vector is "cheap to ignore" per Phase 11 R4.
enum UsageKind: Sendable {
    case capture
    case aiSummary

    var freeLimit: Int {
        switch self {
        case .capture:   return 3
        case .aiSummary: return 5
        }
    }
}

@MainActor
struct UsageQuotaService {
    private static let defaults = UserDefaults.standard

    static func canConsume(_ kind: UsageKind, uid: String?, isPro: Bool, now: Date = Date()) -> Bool {
        if isPro { return true }
        return currentCount(kind, uid: uid, now: now) < kind.freeLimit
    }

    static func remaining(_ kind: UsageKind, uid: String?, isPro: Bool, now: Date = Date()) -> Int {
        if isPro { return .max }
        return max(0, kind.freeLimit - currentCount(kind, uid: uid, now: now))
    }

    static func consume(_ kind: UsageKind, uid: String?, isPro: Bool, now: Date = Date()) -> Bool {
        guard canConsume(kind, uid: uid, isPro: isPro, now: now) else { return false }
        if isPro { return true }
        let key = bucketKey(kind, uid: uid, now: now)
        let next = defaults.integer(forKey: key) + 1
        defaults.set(next, forKey: key)
        return true
    }

    static func currentCount(_ kind: UsageKind, uid: String?, now: Date = Date()) -> Int {
        defaults.integer(forKey: bucketKey(kind, uid: uid, now: now))
    }

    private static func bucketKey(_ kind: UsageKind, uid: String?, now: Date) -> String {
        let identity = (uid?.isEmpty == false ? uid! : "_anon")
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = kind == .capture ? "yyyy-MM-dd" : "yyyy-MM"
        let suffix = kind == .capture ? "capture" : "aiSummary"
        return "quota.\(suffix).\(identity).\(formatter.string(from: now))"
    }
}
