import SwiftData
import SwiftUI

@MainActor
struct FlashcardReviewView: View {
    let deckID: UUID

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthStore.self) private var auth
    @State private var model: ReviewSessionModel?
    @State private var dragOffset: CGSize = .zero
    @State private var hapticArmed = false

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
                let authRef = auth
                model = ReviewSessionModel(
                    deckID: deckID,
                    modelContainer: modelContext.container,
                    uidProvider: { authRef.currentUser?.id }
                )
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
            ? FlashcardFaceView(title: "Answer", text: card.answer, footer: card.hint, isAnswer: true)
            : FlashcardFaceView(title: "Question", text: card.question, footer: card.hint.map { "Hint: \($0)" }, isAnswer: false)

        // Flip transforms stay on the face; tilt/offset/hint live on the outer ZStack so the
        // hint badge isn't mirrored by the answer-side horizontal flip.
        let flippedFace = face
            .rotation3DEffect(.degrees(isAnswer ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            .scaleEffect(x: isAnswer ? -1 : 1, y: 1)

        return ZStack {
            flippedFace
            if isAnswer { swipeHint }
        }
        .frame(maxHeight: 360)
        .rotationEffect(.degrees(tiltDegrees))
        .offset(dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                    armHapticIfCrossed(value.translation)
                }
                .onEnded { value in
                    handleSwipe(value: value)
                }
        )
        .onTapGesture {
            Haptics.tap()
            withAnimation(AppMotion.standard) { model?.flipCard() }
        }
        .animation(AppMotion.standard, value: isAnswer)
        .animation(AppMotion.quick, value: dragOffset)
    }

    // Right = Easy (green), Left = Hard (red), Up = Again (accent). Opacity tracks drag distance.
    @ViewBuilder private var swipeHint: some View {
        let dx = dragOffset.width
        let dy = dragOffset.height
        let horizontal = abs(dx) >= abs(dy)
        let (text, color, strength): (String, Color, CGFloat) = {
            if horizontal {
                return dx >= 0 ? ("EASY", .success, dx) : ("HARD", .danger, -dx)
            } else {
                return dy < 0 ? ("AGAIN", .accent, -dy) : ("", .clear, 0)
            }
        }()
        let opacity = Double(min(max(strength - 20, 0) / 80, 1))

        RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
            .fill(color.opacity(0.16 * opacity))
            .overlay(
                Text(text)
                    .appFont(.h2)
                    .fontWeight(.bold)
                    .foregroundStyle(color)
                    .opacity(opacity)
            )
            .allowsHitTesting(false)
    }

    private var tiltDegrees: Double {
        Double(max(-12, min(12, dragOffset.width / 14)))
    }

    private func armHapticIfCrossed(_ t: CGSize) {
        let crossed = abs(t.width) > 80 || t.height < -80
        if crossed, !hapticArmed { Haptics.selection(); hapticArmed = true }
        if !crossed, hapticArmed { hapticArmed = false }
    }

    private func handleSwipe(value: DragGesture.Value) {
        guard let model else { dragOffset = .zero; return }
        let dx = value.translation.width
        let dy = value.translation.height
        let threshold: CGFloat = 80

        defer {
            withAnimation(AppMotion.quick) { dragOffset = .zero }
            hapticArmed = false
        }

        // Ignore swipes if the answer isn't revealed yet — force flip first.
        guard model.isAnswerVisible else {
            if abs(dx) > threshold || abs(dy) > threshold {
                Haptics.tap()
                withAnimation(AppMotion.standard) { model.flipCard() }
            }
            return
        }

        if dy < -threshold {
            Haptics.notify(.error)
            model.grade(1)   // swipe up → again
        } else if dx > threshold {
            Haptics.notify(.success)
            model.grade(5)   // swipe right → easy
        } else if dx < -threshold {
            Haptics.notify(.warning)
            model.grade(3)   // swipe left → hard
        }
    }

    private func gradeButtons(model: ReviewSessionModel) -> some View {
        HStack(spacing: AppSpacing.md) {
            gradeButton(title: "Again", color: .danger) { Haptics.notify(.error); model.grade(1) }
            gradeButton(title: "Hard",  color: .warning) { Haptics.notify(.warning); model.grade(3) }
            gradeButton(title: "Easy",  color: .success) { Haptics.notify(.success); model.grade(5) }
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
