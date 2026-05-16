import Foundation

// Stored verbatim in SwiftData via rawValue; also serialized to JSON by the
// share-extension queue. Adding a case is a forward-compatible change; never
// renumber.
enum CaptureKind: String, Codable, CaseIterable, Sendable {
    case url
    case text
    case image
}
