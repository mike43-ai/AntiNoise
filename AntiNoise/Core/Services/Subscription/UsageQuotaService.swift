import Foundation

// Free-tier counters. Pro skips all checks. Counters are keyed by UID + window
// (daily or monthly), so a timezone-change abuse vector is "cheap to ignore".
//   capture   — 3/day   capture creation
//   aiSummary — 10/month text summarization (AISummarizer)
//   lesson    — 3/month  layered deck generation (deep-dive + study-this) [v1.1]
//   article   — 1/day    daily-knowledge refresh [v1.1]
enum UsageKind: Sendable {
    case capture
    case aiSummary
    case lesson
    case article

    enum Window { case daily, monthly }

    var window: Window {
        switch self {
        case .capture, .article: return .daily
        case .aiSummary, .lesson: return .monthly
        }
    }

    var freeLimit: Int {
        switch self {
        case .capture:   return 3
        case .aiSummary: return 10
        case .lesson:    return 3
        case .article:   return 1
        }
    }

    var bucketName: String {
        switch self {
        case .capture:   return "capture"
        case .aiSummary: return "aiSummary"
        case .lesson:    return "lesson"
        case .article:   return "article"
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
        formatter.dateFormat = kind.window == .daily ? "yyyy-MM-dd" : "yyyy-MM"
        return "quota.\(kind.bucketName).\(identity).\(formatter.string(from: now))"
    }
}
