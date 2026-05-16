import SwiftData
import SwiftUI

struct DeckListView: View {
    @Environment(\.modelContext) private var modelContext
    let onSelect: (UUID) -> Void

    var body: some View {
        let decks = fetchDecks()
        let dueByDeck = computeDueByDeck()

        if decks.isEmpty {
            AppEmptyState(
                systemImage: "rectangle.stack",
                title: "No decks yet",
                message: "Open a ready summary and tap \"Create flash cards\" to make one."
            )
        } else {
            VStack(spacing: AppSpacing.sm) {
                ForEach(decks) { deck in
                    Button { onSelect(deck.id) } label: {
                        AppCard {
                            HStack(alignment: .top, spacing: AppSpacing.md) {
                                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                    Text(deck.title).appFont(.body).fontWeight(.semibold).lineLimit(2)
                                    HStack(spacing: AppSpacing.sm) {
                                        if let scope = deck.scope {
                                            Chip(title: scope.title.uppercased(), variant: .accent)
                                        }
                                        Text(deck.createdAt, format: .relative(presentation: .named))
                                            .appFont(.caption)
                                            .foregroundStyle(Color.textMuted)
                                    }
                                }
                                Spacer()
                                if let due = dueByDeck[deck.id], due > 0 {
                                    Chip(title: "\(due) due", variant: .danger, isSelected: true)
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func fetchDecks() -> [Deck] {
        let descriptor = FetchDescriptor<Deck>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func computeDueByDeck() -> [UUID: Int] {
        let now = Date()
        let descriptor = FetchDescriptor<Flashcard>(predicate: #Predicate { $0.nextReviewAt <= now })
        let rows = (try? modelContext.fetch(descriptor)) ?? []
        var byDeck: [UUID: Int] = [:]
        for row in rows {
            byDeck[row.deckID, default: 0] += 1
        }
        return byDeck
    }
}
