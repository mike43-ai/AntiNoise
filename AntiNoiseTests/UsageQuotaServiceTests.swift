import XCTest
@testable import AntiNoise

@MainActor
final class UsageQuotaServiceTests: XCTestCase {
    private let cal = Calendar(identifier: .gregorian)

    // Tests share UserDefaults.standard with the host app. Wipe the quota.* keyspace
    // before each test so prior runs / host state never leak into assertions.
    override func setUp() {
        super.setUp()
        let d = UserDefaults.standard
        for key in d.dictionaryRepresentation().keys where key.hasPrefix("quota.") {
            d.removeObject(forKey: key)
        }
    }

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!
    }

    func testProBypassesAllLimits() {
        let uid = UUID().uuidString
        let now = date(2026, 1, 1)
        for _ in 0..<100 {
            XCTAssertTrue(UsageQuotaService.consume(.capture, uid: uid, isPro: true, now: now))
        }
        XCTAssertTrue(UsageQuotaService.canConsume(.capture, uid: uid, isPro: true, now: now))
        XCTAssertEqual(UsageQuotaService.remaining(.aiSummary, uid: uid, isPro: true, now: now), .max)
        // Pro consume never writes a counter
        XCTAssertEqual(UsageQuotaService.currentCount(.capture, uid: uid, now: now), 0)
    }

    func testCaptureFreeLimitIsThreePerDay() {
        let uid = UUID().uuidString
        let now = date(2026, 1, 1)
        for i in 0..<3 {
            XCTAssertTrue(UsageQuotaService.consume(.capture, uid: uid, isPro: false, now: now), "consume #\(i)")
        }
        XCTAssertFalse(UsageQuotaService.canConsume(.capture, uid: uid, isPro: false, now: now))
        XCTAssertFalse(UsageQuotaService.consume(.capture, uid: uid, isPro: false, now: now)) // 4th blocked
        XCTAssertEqual(UsageQuotaService.remaining(.capture, uid: uid, isPro: false, now: now), 0)
    }

    func testDailyBucketRollsOverNextDayButNotSameDay() {
        let uid = UUID().uuidString
        let day1 = date(2026, 1, 1)
        let day2 = date(2026, 1, 2)
        _ = UsageQuotaService.consume(.capture, uid: uid, isPro: false, now: day1)
        XCTAssertEqual(UsageQuotaService.currentCount(.capture, uid: uid, now: day1), 1)
        // Same day, later hour → same bucket
        XCTAssertEqual(UsageQuotaService.currentCount(.capture, uid: uid, now: date(2026, 1, 1)), 1)
        // Next day → fresh bucket
        XCTAssertEqual(UsageQuotaService.currentCount(.capture, uid: uid, now: day2), 0)
    }

    func testMonthlyBucketRollsOverNextMonthButNotNextDay() {
        let uid = UUID().uuidString
        _ = UsageQuotaService.consume(.lesson, uid: uid, isPro: false, now: date(2026, 1, 1))
        // Different day, same month → counter persists
        XCTAssertEqual(UsageQuotaService.currentCount(.lesson, uid: uid, now: date(2026, 1, 28)), 1)
        // Next month → reset
        XCTAssertEqual(UsageQuotaService.currentCount(.lesson, uid: uid, now: date(2026, 2, 1)), 0)
    }

    func testPerKindFreeLimits() {
        XCTAssertEqual(UsageKind.capture.freeLimit, 3)
        XCTAssertEqual(UsageKind.aiSummary.freeLimit, 10)
        XCTAssertEqual(UsageKind.lesson.freeLimit, 3)
        XCTAssertEqual(UsageKind.article.freeLimit, 1)
        XCTAssertEqual(UsageKind.capture.window, .daily)
        XCTAssertEqual(UsageKind.article.window, .daily)
        XCTAssertEqual(UsageKind.aiSummary.window, .monthly)
        XCTAssertEqual(UsageKind.lesson.window, .monthly)
    }

    func testArticleAllowsOnePerDay() {
        let uid = UUID().uuidString
        let now = date(2026, 1, 1)
        XCTAssertTrue(UsageQuotaService.consume(.article, uid: uid, isPro: false, now: now))
        XCTAssertFalse(UsageQuotaService.consume(.article, uid: uid, isPro: false, now: now))
    }

    func testNilAndEmptyUidShareTheAnonBucket() {
        let now = date(2026, 1, 1)
        _ = UsageQuotaService.consume(.capture, uid: nil, isPro: false, now: now)
        // empty string must resolve to the same "_anon" counter as nil
        XCTAssertEqual(UsageQuotaService.currentCount(.capture, uid: "", now: now), 1)
    }

    func testCountersAreIsolatedPerUid() {
        let now = date(2026, 1, 1)
        let a = UUID().uuidString
        let b = UUID().uuidString
        _ = UsageQuotaService.consume(.capture, uid: a, isPro: false, now: now)
        _ = UsageQuotaService.consume(.capture, uid: a, isPro: false, now: now)
        XCTAssertEqual(UsageQuotaService.currentCount(.capture, uid: a, now: now), 2)
        XCTAssertEqual(UsageQuotaService.currentCount(.capture, uid: b, now: now), 0)
    }
}
