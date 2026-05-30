import Foundation

// Locked event list per phase-12 plan. Adding a new event needs a plan
// amendment so the Firebase Analytics dashboard stays in sync.
enum TelemetryEvent {
    case signUp(method: AuthMethod)
    case login(method: AuthMethod)
    case captureCreated(kind: CaptureKind, source: CaptureSource)
    case summarySucceeded(kind: CaptureKind, latencyMs: Int)
    case summaryFailed(kind: CaptureKind, errorCode: String)
    case deepDiveStarted
    case deckGenerated(cardCount: Int)
    case reviewSessionCompleted(cardsReviewed: Int, correctCount: Int)
    case learnPathStarted(topic: String)
    case learnDayCompleted(dayIndex: Int)
    case learnPathCompleted(topic: String)
    case learnPathAbandoned(atDay: Int)
    case trialStarted
    case trialExpired
    case paywallShown(trigger: PaywallTrigger)
    case subscriptionStarted(productID: String)
    case quotaHit(kind: QuotaEventKind)
    case notificationOptIn(categories: [String])
    case notificationTapped(category: String)
    case accountExport
    case accountDeleted

    var name: String {
        switch self {
        case .signUp:                  return "sign_up"
        case .login:                   return "login"
        case .captureCreated:          return "capture_created"
        case .summarySucceeded:        return "summary_succeeded"
        case .summaryFailed:           return "summary_failed"
        case .deepDiveStarted:         return "deep_dive_started"
        case .deckGenerated:           return "deck_generated"
        case .reviewSessionCompleted:  return "review_session_completed"
        case .learnPathStarted:        return "learn_path_started"
        case .learnDayCompleted:       return "learn_day_completed"
        case .learnPathCompleted:      return "learn_path_completed"
        case .learnPathAbandoned:      return "learn_path_abandoned"
        case .trialStarted:            return "trial_started"
        case .trialExpired:            return "trial_expired"
        case .paywallShown:            return "paywall_shown"
        case .subscriptionStarted:     return "subscription_started"
        case .quotaHit:                return "quota_hit"
        case .notificationOptIn:       return "notification_opt_in"
        case .notificationTapped:      return "notification_tapped"
        case .accountExport:           return "account_export"
        case .accountDeleted:          return "account_deleted"
        }
    }

    var params: [String: Any]? {
        switch self {
        case .signUp(let method), .login(let method):
            return ["method": method.rawValue]
        case .captureCreated(let kind, let source):
            return ["kind": kind.rawValue, "source": source.rawValue]
        case .summarySucceeded(let kind, let latencyMs):
            return ["kind": kind.rawValue, "latency_ms": latencyMs]
        case .summaryFailed(let kind, let errorCode):
            return ["kind": kind.rawValue, "error_code": errorCode]
        case .deckGenerated(let cardCount):
            return ["card_count": cardCount]
        case .reviewSessionCompleted(let reviewed, let correct):
            return ["cards_reviewed": reviewed, "correct_count": correct]
        case .learnPathStarted(let topic), .learnPathCompleted(let topic):
            return ["topic": topic]
        case .learnDayCompleted(let dayIndex):
            return ["day_index": dayIndex]
        case .learnPathAbandoned(let atDay):
            return ["at_day": atDay]
        case .paywallShown(let trigger):
            return ["trigger": trigger.rawValue]
        case .subscriptionStarted(let productID):
            return ["product_id": productID]
        case .quotaHit(let kind):
            return ["kind": kind.rawValue]
        case .notificationOptIn(let categories):
            return ["categories": categories.joined(separator: ",")]
        case .notificationTapped(let category):
            return ["category": category]
        case .deepDiveStarted, .trialStarted, .trialExpired,
             .accountExport, .accountDeleted:
            return nil
        }
    }
}

enum AuthMethod: String {
    case apple
    case google
}

enum CaptureSource: String {
    case inApp = "in_app"
    case shareExt = "share_ext"
}

enum PaywallTrigger: String {
    case trialExpiry = "trial_expiry"
    case quotaCapture = "quota_capture"
    case quotaAI = "quota_ai"
    case profileUpgrade = "profile_upgrade"
    case deepLearn = "deep_learn"
}

// UsageKind is service-internal (consume() / canConsume()). Surface a flat
// string for analytics so we don't leak the enum's case names if they change.
enum QuotaEventKind: String {
    case capture
    case aiSummary = "ai_summary"
    case lesson
    case article

    init(_ kind: UsageKind) {
        switch kind {
        case .capture:   self = .capture
        case .aiSummary: self = .aiSummary
        case .lesson:    self = .lesson
        case .article:   self = .article
        }
    }
}
