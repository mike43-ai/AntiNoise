import Foundation
import SwiftData

/// Cold-start content. On a user's first launch, inserts 1–2 bundled evergreen
/// layered sample decks matching their chosen topic packs (fallback Productivity)
/// so the Learn tab isn't empty before they capture anything. Idempotent per uid.
@MainActor
enum SeedDeckRepository {
    private struct SeedFile: Decodable { let decks: [SeedDeck] }
    private struct SeedDeck: Decodable {
        let pack: String
        let title: String
        let cards: [SeedCard]
    }
    private struct SeedCard: Decodable {
        let question: String
        let answer: String
        let hint: String?
        let difficulty: Int
        let layer: Int
    }

    private static func seededKey(_ uid: String) -> String { "seededDecks.\(uid)" }

    static func seedIfNeeded(uid: String, context: ModelContext) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: seededKey(uid)) else { return }

        // A missing bundle should retry on a later launch rather than permanently
        // skip — so only claim the seeded flag after a successful save (this method
        // is synchronous + @MainActor, so it runs atomically: no double-seed race).
        guard let all = loadSeedFile()?.decks, !all.isEmpty else { return }

        let packs = Set(OnboardingStore.topicPacks(uid: uid).map(\.rawValue))
        var chosen = all.filter { packs.contains($0.pack) }
        if chosen.isEmpty { chosen = all.filter { $0.pack == "productivity" } } // fallback
        if chosen.isEmpty { chosen = Array(all.prefix(1)) }

        for seed in chosen.prefix(2) { insert(seed, context: context) }
        do {
            try context.save()
            defaults.set(true, forKey: seededKey(uid))
        } catch {
            print("[AntiNoise] SeedDeckRepository save failed: \(error)") // leave flag unset → retry
        }
    }

    private static func insert(_ seed: SeedDeck, context: ModelContext) {
        let deck = Deck(title: seed.title, isLayered: true, isSample: true)
        context.insert(deck)
        for card in seed.cards {
            context.insert(Flashcard(
                deckID: deck.id,
                question: card.question,
                answer: card.answer,
                hint: card.hint,
                difficulty: card.difficulty,
                layerIndex: max(0, min(2, card.layer))
            ))
        }
    }

    private static func loadSeedFile() -> SeedFile? {
        guard let url = Bundle.main.url(forResource: "SeedDecks", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(SeedFile.self, from: data)
    }
}
