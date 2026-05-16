import Foundation

// Pure scoring function. No side effects, deterministic given the inputs.
// score = w_r * recency(capturedAt, now)
//       + w_s * scopeAlignment(captureScope, userScopes)
//       + w_d * (recommendDeepDive ? 1 : 0)
//       - w_p * log(1 + skipCount)
enum PriorityScorer {
    static func score(
        capture: Capture,
        summary: Summary?,
        userScopes: Set<ClassificationScope>,
        now: Date = Date(),
        weights: PriorityWeights = .default
    ) -> Double {
        let scope = resolveScope(capture: capture, summary: summary)

        let recency = recencyFactor(capturedAt: capture.capturedAt, now: now, halfLifeDays: weights.recencyHalfLifeDays)
        let alignment = scopeAlignment(scope: scope, userScopes: userScopes)
        let deepDive = (summary?.recommendDeepDive ?? false) ? 1.0 : 0.0
        let skipPenalty = log(1.0 + Double(capture.skipCount))

        return weights.recency      * recency
             + weights.scopeAlignment * alignment
             + weights.deepDive     * deepDive
             - weights.skipPenalty  * skipPenalty
    }

    static func resolveScope(capture: Capture?, summary: Summary?) -> ClassificationScope? {
        if let override = capture?.userClassification { return override }
        return summary?.suggestedClassification
    }

    // Exponential decay: 1.0 at now, 0.5 at halfLifeDays old.
    private static func recencyFactor(capturedAt: Date, now: Date, halfLifeDays: Double) -> Double {
        let seconds = max(0, now.timeIntervalSince(capturedAt))
        let days = seconds / 86_400.0
        let lambda = log(2.0) / max(0.0001, halfLifeDays)
        return exp(-lambda * days)
    }

    // 1.0 if scope is in user's chosen scopes; 0.4 if user has scopes set but
    // this one doesn't match; 0.7 if user has no scopes (don't penalize hard).
    private static func scopeAlignment(scope: ClassificationScope?, userScopes: Set<ClassificationScope>) -> Double {
        guard let scope else { return 0.5 }
        if userScopes.isEmpty { return 0.7 }
        return userScopes.contains(scope) ? 1.0 : 0.4
    }
}
