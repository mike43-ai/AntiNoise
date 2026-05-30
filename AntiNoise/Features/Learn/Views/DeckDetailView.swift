import SwiftData
import SwiftUI

struct DeckDetailView: View {
    let deckID: UUID
    @Environment(\.modelContext) private var modelContext
    @State private var navigateToReview = false

    var body: some View {
        let deck = fetchDeck()
        let cards = fetchCards()
        let dueCount = cards.filter { $0.nextReviewAt <= Date() }.count

        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                if let deck {
                    header(deck: deck, total: cards.count, dueCount: dueCount)
                }

                if cards.isEmpty {
                    AppEmptyState(systemImage: "rectangle.stack", title: "No cards yet")
                } else {
                    cardsList(cards)
                }
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.lg)
        }
        .background(Color.bgPrimary)
        .navigationTitle(deck?.title ?? "Deck")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToReview) {
            FlashcardReviewView(deckID: deckID)
        }
    }

    private func header(deck: Deck, total: Int, dueCount: Int) -> some View {
        AppCard(style: .elevated) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack {
                    Text(deck.title).appFont(.h2)
                    Spacer()
                    if let scope = deck.scope {
                        Chip(title: scope.title.uppercased(), variant: .accent)
                    }
                }
                HStack(spacing: AppSpacing.lg) {
                    stat(label: "Cards", value: total)
                    stat(label: "Due now", value: dueCount)
                }
                PrimaryButton(
                    title: dueCount > 0 ? "Start review · \(dueCount)" : "Nothing due",
                    isDisabled: dueCount == 0
                ) {
                    navigateToReview = true
                }
                DeepLearnStartButton(deck: deck)
            }
        }
    }

    private func cardsList(_ cards: [Flashcard]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Cards").appFont(.caption).textCase(.uppercase).foregroundStyle(Color.textMuted)
            ForEach(cards) { card in
                AppCard {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(card.question).appFont(.body).fontWeight(.semibold)
                        Text(card.answer).appFont(.bodySmall).foregroundStyle(Color.textMuted).lineLimit(3)
                        HStack(spacing: AppSpacing.sm) {
                            Chip(title: "Difficulty \(card.difficulty)", variant: .neutral)
                            Text(card.nextReviewAt <= Date() ? "Due" : "Next: \(card.nextReviewAt, format: .relative(presentation: .named))")
                                .appFont(.caption)
                                .foregroundStyle(Color.textMuted)
                            Spacer()
                        }
                    }
                }
            }
        }
    }

    private func stat(label: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(value)").appFont(.h2)
            Text(label).appFont(.caption).foregroundStyle(Color.textMuted).textCase(.uppercase)
        }
    }

    private func fetchDeck() -> Deck? {
        let id = deckID
        let descriptor = FetchDescriptor<Deck>(predicate: #Predicate { $0.id == id })
        return (try? modelContext.fetch(descriptor))?.first
    }

    private func fetchCards() -> [Flashcard] {
        let id = deckID
        let descriptor = FetchDescriptor<Flashcard>(
            predicate: #Predicate { $0.deckID == id },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
}
