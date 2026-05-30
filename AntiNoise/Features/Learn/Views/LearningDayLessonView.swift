import SwiftData
import SwiftUI

/// One day's micro-lesson: a Feynman concept (lazily generated on first open),
/// then the day's new cards (reusing the shared review), then an apply prompt.
/// Completing the day advances the course.
@MainActor
struct LearningDayLessonView: View {
    let dayIndex: Int
    let model: DeepLearnModel?

    @Environment(\.dismiss) private var dismiss
    @State private var reviewing = false

    private var day: LearningDay? { model?.days.first { $0.dayIndex == dayIndex } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                if let model, model.isWorking, day?.isGenerated != true {
                    loading
                } else if let error = model?.errorMessage, day?.isGenerated != true {
                    errorState(error)
                } else if let day, day.isGenerated {
                    lesson(day: day)
                } else {
                    loading
                }
            }
            .padding(AppSpacing.xl)
        }
        .background(Color.bgPrimary)
        .navigationTitle("Day \(dayIndex)")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $reviewing) {
            if let deckID = model?.activePath?.deckID {
                FlashcardReviewView(deckID: deckID)
            }
        }
        .task {
            if let model, let day, !day.isGenerated { await model.ensureDayContent(day) }
        }
    }

    private var loading: some View {
        VStack(spacing: AppSpacing.md) {
            AppLoadingIndicator()
            Text("⚡ Preparing today's lesson…").appFont(.bodySmall).foregroundStyle(Color.textMuted)
        }
        .frame(maxWidth: .infinity, minHeight: 320)
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: AppSpacing.md) {
            AppEmptyState(systemImage: "exclamationmark.triangle", title: "Couldn't load", message: message)
            PrimaryButton(title: "Try again") {
                Task { if let model, let day { await model.ensureDayContent(day) } }
            }
        }
    }

    @ViewBuilder
    private func lesson(day: LearningDay) -> some View {
        AppCard(style: .elevated) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("CONCEPT").appFont(.caption).foregroundStyle(Color.accent)
                Text(day.conceptText ?? "").appFont(.body)
            }
        }

        PrimaryButton(title: "Review today's cards") { reviewing = true }

        if let apply = day.applyPrompt, !apply.isEmpty {
            AppCard {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("APPLY IT").appFont(.caption).foregroundStyle(Color.accent)
                    Text(apply).appFont(.body)
                }
            }
        }

        if day.isCompleted {
            Text("✓ Completed").appFont(.body).foregroundStyle(Color.success)
                .frame(maxWidth: .infinity)
        } else {
            SecondaryButton(title: "Mark day complete") {
                model?.completeDay(dayIndex)
                dismiss()
            }
        }
    }
}
