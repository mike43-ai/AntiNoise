import SwiftData
import SwiftUI

struct FlashcardReviewView: View {
    let deckID: UUID

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var model: ReviewSessionModel?
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        Group {
            if let model {
                content(model: model)
            } else {
                AppLoadingIndicator()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.bgPrimary.ignoresSafeArea())
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
                    .tint(Color.textPrimary)
            }
        }
        .task {
            if model == nil {
                model = ReviewSessionModel(deckID: deckID, modelContainer: modelContext.container)
                model?.start()
            }
        }
    }

    @ViewBuilder
    private func content(model: ReviewSessionModel) -> some View {
        switch model.state {
        case .reviewing:
            reviewing(model: model)
        case .finished:
            ReviewSummaryView(
                total: model.totalReviewed,
                correct: model.correctCount,
                lapses: model.lapseCount,
                onDone: { dismiss() }
            )
        }
    }

    @ViewBuilder
    private func reviewing(model: ReviewSessionModel) -> some View {
        if let card = model.currentCard {
            VStack(spacing: AppSpacing.lg) {
                ProgressView(value: progress(model: model))
                    .tint(Color.accent)
                    .padding(.horizontal, AppSpacing.xl)

                cardStack(card: card, isAnswer: model.isAnswerVisible)
                    .padding(.horizontal, AppSpacing.xl)

                gradeButtons(model: model)
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.bottom, AppSpacing.lg)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            AppEmptyState(
                systemImage: "checkmark.seal",
                title: "Nothing due here.",
                message: "All cards in this deck are scheduled for later."
            )
        }
    }

    private func cardStack(card: Flashcard, isAnswer: Bool) -> some View {
        let face = isAnswer
            ? FlashcardFaceView(title: "Answer", body: card.answer, footer: card.hint, isAnswer: true)
            : FlashcardFaceView(title: "Question", body: card.question, footer: card.hint.map { "Hint: \($0)" }, isAnswer: false)

        return face
            .frame(maxHeight: 360)
            .rotation3DEffect(.degrees(isAnswer ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            .scaleEffect(x: isAnswer ? -1 : 1, y: 1)
            .offset(dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { dragOffset = $0.translation }
                    .onEnded { value in
                        handleSwipe(value: value)
                    }
            )
            .onTapGesture {
                withAnimation(AppMotion.standard) { model?.flipCard() }
            }
            .animation(AppMotion.standard, value: isAnswer)
    }

    private func handleSwipe(value: DragGesture.Value) {
        guard let model else { dragOffset = .zero; return }
        let dx = value.translation.width
        let dy = value.translation.height
        let threshold: CGFloat = 80

        defer {
            withAnimation(AppMotion.quick) { dragOffset = .zero }
        }

        // Ignore swipes if the answer isn't revealed yet — force flip first.
        guard model.isAnswerVisible else {
            if abs(dx) > threshold || abs(dy) > threshold {
                withAnimation(AppMotion.standard) { model.flipCard() }
            }
            return
        }

        if dy < -threshold {
            model.grade(1)   // swipe up → again
        } else if dx > threshold {
            model.grade(5)   // swipe right → easy
        } else if dx < -threshold {
            model.grade(3)   // swipe left → hard
        }
    }

    private func gradeButtons(model: ReviewSessionModel) -> some View {
        HStack(spacing: AppSpacing.md) {
            gradeButton(title: "Again", color: .danger) { model.grade(1) }
            gradeButton(title: "Hard",  color: .textPrimary) { model.grade(3) }
            gradeButton(title: "Easy",  color: .success) { model.grade(5) }
        }
        .opacity(model.isAnswerVisible ? 1 : 0.4)
        .disabled(!model.isAnswerVisible)
    }

    private func gradeButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .appFont(.bodySmall)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func progress(model: ReviewSessionModel) -> Double {
        let total = model.queue.count
        guard total > 0 else { return 0 }
        return Double(min(model.index, total)) / Double(total)
    }
}
