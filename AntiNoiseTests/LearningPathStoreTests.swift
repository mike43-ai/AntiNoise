import XCTest
import SwiftData
@testable import AntiNoise

@MainActor
final class LearningPathStoreTests: XCTestCase {
    // SwiftData test container with only the models the store touches.
    private func makeContext() throws -> ModelContext {
        let schema = Schema([Deck.self, Flashcard.self, LearningPath.self, LearningDay.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    func testCreatePathInsertsPathPlusSevenDays() throws {
        let store = LearningPathStore(context: try makeContext())
        let path = store.createPath(deckID: UUID(), topic: "RAG", outlineJSON: "{}")
        XCTAssertEqual(path.durationDays, 7)
        XCTAssertEqual(path.currentDay, 1)
        XCTAssertEqual(path.statusValue, .active)
        XCTAssertEqual(store.days(for: path.id).map(\.dayIndex), Array(1...7))
        XCTAssertEqual(store.fetchActivePath()?.id, path.id)
    }

    func testFillDaySetsContentAndCardIDs() throws {
        let store = LearningPathStore(context: try makeContext())
        let path = store.createPath(deckID: UUID(), topic: "T", outlineJSON: nil)
        let ids = [UUID(), UUID()]
        store.fillDay(pathID: path.id, dayIndex: 2, concept: "C", applyPrompt: "A", cardIDs: ids)
        let day = store.day(pathID: path.id, dayIndex: 2)
        XCTAssertEqual(day?.conceptText, "C")
        XCTAssertEqual(day?.applyPrompt, "A")
        XCTAssertEqual(day?.cardIDs, ids)
        XCTAssertTrue(day?.isGenerated == true)
    }

    func testMarkDayCompleteAdvancesCurrentDay() throws {
        let store = LearningPathStore(context: try makeContext())
        let path = store.createPath(deckID: UUID(), topic: "T", outlineJSON: nil)
        store.markDayComplete(pathID: path.id, dayIndex: 1)
        XCTAssertNotNil(store.day(pathID: path.id, dayIndex: 1)?.completedAt)
        XCTAssertEqual(store.path(id: path.id)?.currentDay, 2)
    }

    func testCompletingFinalDayDoesNotOverflowCurrentDay() throws {
        let store = LearningPathStore(context: try makeContext())
        let path = store.createPath(deckID: UUID(), topic: "T", outlineJSON: nil)
        store.markDayComplete(pathID: path.id, dayIndex: 7)
        XCTAssertEqual(store.path(id: path.id)?.currentDay, 7) // clamped to durationDays
    }

    func testAbandonKeepsCardsButFlipsStatus() throws {
        let context = try makeContext()
        let store = LearningPathStore(context: context)
        let deckID = UUID()
        let path = store.createPath(deckID: deckID, topic: "T", outlineJSON: nil)
        // simulate generated cards living in the path's deck
        context.insert(Flashcard(deckID: deckID, question: "q", answer: "a"))
        try context.save()

        store.abandonPath(pathID: path.id)
        XCTAssertEqual(store.path(id: path.id)?.statusValue, .abandoned)
        XCTAssertNil(store.fetchActivePath()) // abandoned no longer "active"
        // cards are intentionally retained in the SRS queue
        let cards = try context.fetch(FetchDescriptor<Flashcard>())
        XCTAssertEqual(cards.count, 1)
    }

    func testMarkPathComplete() throws {
        let store = LearningPathStore(context: try makeContext())
        let path = store.createPath(deckID: UUID(), topic: "T", outlineJSON: nil)
        store.markPathComplete(pathID: path.id)
        XCTAssertEqual(store.path(id: path.id)?.statusValue, .completed)
    }
}
