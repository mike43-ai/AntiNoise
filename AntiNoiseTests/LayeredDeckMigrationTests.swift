import XCTest
import SwiftData
@testable import AntiNoise

@MainActor
final class LayeredDeckMigrationTests: XCTestCase {
    private let cal = Calendar(identifier: .gregorian)
    private lazy var now: Date = cal.date(from: DateComponents(year: 2026, month: 1, day: 15, hour: 12))!

    private static let schema = Schema([
        Capture.self, Summary.self, LearningGoal.self,
        Deck.self, Flashcard.self, FocusSession.self, DailySkillItem.self,
    ])

    private func inMemoryContainer() throws -> ModelContainer {
        let config = ModelConfiguration(schema: Self.schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: Self.schema, configurations: [config])
    }

    private func fileContainer(at url: URL) throws -> ModelContainer {
        let config = ModelConfiguration(schema: Self.schema, url: url)
        return try ModelContainer(for: Self.schema, configurations: [config])
    }

    // MARK: - Layered ordering

    func testDueCardsOrderByLayerThenOverdue() throws {
        let container = try inMemoryContainer()
        let ctx = ModelContext(container)
        let deck = Deck(title: "Layered", isLayered: true)
        ctx.insert(deck)

        func card(_ layer: Int, _ daysAgo: Int) -> Flashcard {
            Flashcard(
                deckID: deck.id, question: "q\(layer)-\(daysAgo)", answer: "a",
                layerIndex: layer, nextReviewAt: now.addingTimeInterval(Double(-daysAgo) * 86_400)
            )
        }
        // Insert deliberately out of final order
        let a = card(2, 10)
        let b = card(0, 1)
        let c = card(0, 5)
        let d = card(1, 2)
        [a, b, d, c].forEach { ctx.insert($0) }
        try ctx.save()

        let engine = ReviewSessionEngine(modelContainer: container)
        let due = engine.dueCards(for: deck.id, now: now)
        // layer asc, then most-overdue (smallest nextReviewAt) first within a layer
        XCTAssertEqual(due.map(\.question), ["q0-5", "q0-1", "q1-2", "q2-10"])
    }

    func testFutureCardsAreNotDue() throws {
        let container = try inMemoryContainer()
        let ctx = ModelContext(container)
        let deck = Deck(title: "D", isLayered: true)
        ctx.insert(deck)
        ctx.insert(Flashcard(deckID: deck.id, question: "due", answer: "a", nextReviewAt: now.addingTimeInterval(-100)))
        ctx.insert(Flashcard(deckID: deck.id, question: "future", answer: "a", nextReviewAt: now.addingTimeInterval(86_400)))
        try ctx.save()

        let due = ReviewSessionEngine(modelContainer: container).dueCards(for: deck.id, now: now)
        XCTAssertEqual(due.map(\.question), ["due"])
    }

    // MARK: - Migration safety (literal defaults)

    /// A store written with the v1.1 schema must reopen without a fatalError, and a
    /// deck created the legacy way (no layered args) must carry the literal defaults
    /// (isLayered=false, layerIndex=0) and still review in plain nextReviewAt order —
    /// the same guarantee a real v1.0→v1.1 lightweight migration relies on.
    func testLegacyDeckRoundTripsAndReviewsNormally() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("migration-\(UUID().uuidString).store")
        defer { try? FileManager.default.removeItem(at: url) }

        // First boot: write a "legacy" deck using the minimal initializer.
        do {
            let container = try fileContainer(at: url)
            let ctx = ModelContext(container)
            let deck = Deck(title: "Legacy") // isLayered defaults false
            ctx.insert(deck)
            ctx.insert(Flashcard(deckID: deck.id, question: "old1", answer: "a", nextReviewAt: now.addingTimeInterval(-200)))
            ctx.insert(Flashcard(deckID: deck.id, question: "old2", answer: "a", nextReviewAt: now.addingTimeInterval(-100)))
            try ctx.save()
        }

        // Second boot: a fresh container over the SAME store must not crash and must
        // read the defaulted columns back correctly.
        let reopened = try fileContainer(at: url)
        let ctx = ModelContext(reopened)
        let decks = try ctx.fetch(FetchDescriptor<Deck>())
        XCTAssertEqual(decks.count, 1)
        XCTAssertFalse(decks[0].isLayered)
        XCTAssertFalse(decks[0].isSample)

        let cards = try ctx.fetch(FetchDescriptor<Flashcard>())
        XCTAssertEqual(cards.count, 2)
        XCTAssertTrue(cards.allSatisfy { $0.layerIndex == 0 })

        // Flat deck: layer-first ordering collapses to nextReviewAt ascending.
        let due = ReviewSessionEngine(modelContainer: reopened).dueCards(for: decks[0].id, now: now)
        XCTAssertEqual(due.map(\.question), ["old1", "old2"])
    }
}
