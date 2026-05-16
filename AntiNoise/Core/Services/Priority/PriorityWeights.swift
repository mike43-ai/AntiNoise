import Foundation

// Tunable weights for the daily priority scoring function.
// Defaults picked empirically; Phase 12 may add a debug screen for live-tuning.
struct PriorityWeights: Sendable {
    var recency: Double          = 1.0
    var scopeAlignment: Double   = 1.5
    var deepDive: Double         = 0.8
    var skipPenalty: Double      = 0.6
    /// Half-life in days for the recency factor. Lower = sharper decay.
    var recencyHalfLifeDays: Double = 5

    static let `default` = PriorityWeights()
}
