import XCTest
import SwiftData
@testable import AntiNoise

/// After retiring Focus, the displayed streak must come from review activity
/// (StreakEngine), not Focus sessions. These lock that wiring.
@MainActor
final class StatsAggregatorStreakTests: XCTestCase {
    private let cal = Calendar(identifier: .gregorian)

    override func setUp() {
        super.setUp()
        let d = UserDefaults.standard
        for key in d.dictionaryRepresentation().keys where key.hasPrefix("streak.") {
            d.removeObject(forKey: key)
        }
    }

    private func date(_ y: Int, _ m: Int, _ day: Int) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: day, hour: 12))!
    }

    private func container() throws -> ModelContainer {
        let schema = Schema([Capture.self, Summary.self, Deck.self, Flashcard.self, LearningGoal.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    func testDisplayedStreakMatchesReviewStreak() throws {
        let uid = UUID().uuidString
        let engine = StreakEngine(uid: uid)
        engine.markReviewedToday(now: date(2026, 1, 1))
        engine.markReviewedToday(now: date(2026, 1, 2))
        let today = date(2026, 1, 2)

        let aggregator = StatsAggregator(modelContainer: try container(), uidProvider: { uid })
        let stats = aggregator.compute(now: today)

        XCTAssertEqual(stats.streakDays, 2)
        XCTAssertEqual(stats.streakDays, engine.currentStreak(now: today))
    }

    func testStreakIsZeroWithNoReviews() throws {
        let uid = UUID().uuidString
        let aggregator = StatsAggregator(modelContainer: try container(), uidProvider: { uid })
        XCTAssertEqual(aggregator.compute(now: date(2026, 1, 2)).streakDays, 0)
    }

    func testStreakBreaksWhenADayIsMissed() throws {
        let uid = UUID().uuidString
        let engine = StreakEngine(uid: uid)
        engine.markReviewedToday(now: date(2026, 1, 1))
        // skip Jan 2
        engine.markReviewedToday(now: date(2026, 1, 3))
        let aggregator = StatsAggregator(modelContainer: try container(), uidProvider: { uid })
        XCTAssertEqual(aggregator.compute(now: date(2026, 1, 3)).streakDays, 1)
    }
}
