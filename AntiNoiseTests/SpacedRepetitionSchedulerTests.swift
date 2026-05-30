import XCTest
@testable import AntiNoise

final class SpacedRepetitionSchedulerTests: XCTestCase {
    private let cal = Calendar(identifier: .gregorian)
    private lazy var now: Date = cal.date(from: DateComponents(year: 2026, month: 1, day: 1))!

    private func daysBetween(_ a: Date, _ b: Date) -> Int {
        cal.dateComponents([.day], from: a, to: b).day ?? -1
    }

    func testLapseResetsRepetitionsAndRelearnsInOneDay() {
        let out = SpacedRepetitionScheduler.next(
            easeFactor: 2.5, intervalDays: 30, repetitions: 4, grade: 1, now: now, calendar: cal
        )
        XCTAssertEqual(out.repetitions, 0)
        XCTAssertEqual(out.intervalDays, SM2Constants.firstIntervalDays) // 1
        XCTAssertEqual(out.easeFactor, 2.5, accuracy: 0.0001) // EF unchanged on lapse (Anki classic)
        XCTAssertEqual(daysBetween(now, out.nextReviewAt), 1)
    }

    func testFirstSuccessSchedulesOneDay() {
        let out = SpacedRepetitionScheduler.next(
            easeFactor: 2.5, intervalDays: 0, repetitions: 0, grade: 5, now: now, calendar: cal
        )
        XCTAssertEqual(out.repetitions, 1)
        XCTAssertEqual(out.intervalDays, 1)
    }

    func testSecondSuccessSchedulesSixDays() {
        let out = SpacedRepetitionScheduler.next(
            easeFactor: 2.5, intervalDays: 1, repetitions: 1, grade: 5, now: now, calendar: cal
        )
        XCTAssertEqual(out.repetitions, 2)
        XCTAssertEqual(out.intervalDays, SM2Constants.secondIntervalDays) // 6
    }

    func testThirdSuccessMultipliesByEaseFactor() {
        // interval = round(prevInterval * OLD easeFactor) = round(6 * 2.5) = 15
        let out = SpacedRepetitionScheduler.next(
            easeFactor: 2.5, intervalDays: 6, repetitions: 2, grade: 5, now: now, calendar: cal
        )
        XCTAssertEqual(out.repetitions, 3)
        XCTAssertEqual(out.intervalDays, 15)
        XCTAssertGreaterThan(out.easeFactor, 2.5) // grade 5 nudges EF up
    }

    func testEaseFactorClampedAtFloor() {
        // grade 3 has a negative EF delta; from the floor it must not drop below 1.3
        let out = SpacedRepetitionScheduler.next(
            easeFactor: SM2Constants.minEaseFactor, intervalDays: 10, repetitions: 5, grade: 3, now: now, calendar: cal
        )
        XCTAssertEqual(out.easeFactor, SM2Constants.minEaseFactor, accuracy: 0.0001)
    }

    func testGradeIsClampedIntoZeroToFive() {
        // grade 9 clamps to 5 → behaves like a success, not a crash/overflow
        let out = SpacedRepetitionScheduler.next(
            easeFactor: 2.5, intervalDays: 0, repetitions: 0, grade: 9, now: now, calendar: cal
        )
        XCTAssertEqual(out.repetitions, 1)
    }
}
