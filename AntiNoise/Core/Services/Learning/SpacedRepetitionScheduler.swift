import Foundation

// Canonical SM-2 (Anki classic). Grades 0–5. The UI maps swipes to {1, 3, 5}.
// On grade < 3: repetitions reset, interval = 1 day (relearn).
// On grade ≥ 3: repetition advances; interval is 1 / 6 / round(prev * EF) for
// repetitions = 1 / 2 / 3+. EF adjusted via the Anki formula, clamped to 1.3.
struct SchedulerOutcome: Equatable {
    let easeFactor: Double
    let intervalDays: Int
    let repetitions: Int
    let nextReviewAt: Date
}

enum SpacedRepetitionScheduler {
    static func next(
        easeFactor: Double,
        intervalDays: Int,
        repetitions: Int,
        grade: Int,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> SchedulerOutcome {
        let clampedGrade = max(0, min(5, grade))

        if clampedGrade < 3 {
            let nextDate = calendar.date(byAdding: .day, value: SM2Constants.firstIntervalDays, to: now) ?? now
            return SchedulerOutcome(
                easeFactor: easeFactor,        // EF unchanged on lapse — Anki classic
                intervalDays: SM2Constants.firstIntervalDays,
                repetitions: 0,
                nextReviewAt: nextDate
            )
        }

        let newReps = repetitions + 1
        let newInterval: Int
        switch newReps {
        case 1: newInterval = SM2Constants.firstIntervalDays
        case 2: newInterval = SM2Constants.secondIntervalDays
        default:
            let raw = Double(intervalDays) * easeFactor
            newInterval = max(1, Int((raw).rounded()))
        }

        // SM-2 EF update: EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
        let q = Double(clampedGrade)
        let diff = 5.0 - q
        let efDelta = 0.1 - diff * (0.08 + diff * 0.02)
        let newEF = max(SM2Constants.minEaseFactor, easeFactor + efDelta)

        let nextDate = calendar.date(byAdding: .day, value: newInterval, to: now) ?? now

        return SchedulerOutcome(
            easeFactor: newEF,
            intervalDays: newInterval,
            repetitions: newReps,
            nextReviewAt: nextDate
        )
    }

    static func apply(_ outcome: SchedulerOutcome, to card: Flashcard, grade: Int) {
        card.easeFactor = outcome.easeFactor
        card.intervalDays = outcome.intervalDays
        card.repetitions = outcome.repetitions
        card.nextReviewAt = outcome.nextReviewAt
        card.lastGrade = grade
    }
}
