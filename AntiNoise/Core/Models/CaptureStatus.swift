import Foundation

enum CaptureStatus: String, Codable, CaseIterable, Sendable {
    case queued       // pending AI summary — created locally or via share extension
    case processing   // currently running through SummarizerService
    case summarized   // AI summary stored
    case failed       // SummarizerService gave up after retries
    case archived     // user-archived; hidden from Learn inbox

    var displayName: String {
        switch self {
        case .queued:     return "Queued"
        case .processing: return "Summarizing"
        case .summarized: return "Ready"
        case .failed:     return "Failed"
        case .archived:   return "Archived"
        }
    }
}
