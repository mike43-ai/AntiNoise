import SwiftData
import SwiftUI

/// The active Deep Learn course: a 7-day list with open pacing (no locks). Tapping
/// a day opens its lesson, lazily generating content the first time. Day 7 done →
/// completion badge.
@MainActor
struct LearningPathView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthStore.self) private var auth
    @Environment(SubscriptionStore.self) private var subscription
    @State private var model: DeepLearnModel?
    @State private var openDay: LearningDay?

    var body: some View {
        Group {
            if let model {
                content(model: model)
            } else {
                AppLoadingIndicator().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.bgPrimary)
        .navigationTitle("Deep Learn")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $openDay) { day in
            LearningDayLessonView(dayIndex: day.dayIndex, model: model)
        }
        .task {
            if model == nil {
                let authRef = auth, subRef = subscription
                model = DeepLearnModel(
                    modelContext: modelContext,
                    client: AIClient(isProProvider: { subRef.isPro }),
                    uidProvider: { authRef.currentUser?.id }
                )
            }
            model?.refresh()
        }
    }

    @ViewBuilder
    private func content(model: DeepLearnModel) -> some View {
        if let path = model.activePath {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    if path.statusValue == .completed {
                        completionBadge(topic: path.topic)
                    } else {
                        progressHeader(path: path, current: model.currentDayIndex)
                    }
                    ForEach(model.days, id: \.id) { day in
                        dayRow(day: day, current: model.currentDayIndex)
                    }
                    if path.statusValue == .active {
                        SecondaryButton(title: "Abandon course") { model.abandon() }
                            .padding(.top, AppSpacing.md)
                    }
                }
                .padding(AppSpacing.xl)
            }
        } else {
            AppEmptyState(systemImage: "graduationcap", title: "No active course",
                          message: "Open a deck and start a 7-day Deep Learn course.")
        }
    }

    private func progressHeader(path: LearningPath, current: Int) -> some View {
        AppCard(style: .elevated) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(path.topic).appFont(.h3)
                Text("Day \(min(current, path.durationDays)) of \(path.durationDays)")
                    .appFont(.caption).textCase(.uppercase).foregroundStyle(Color.textMuted)
            }
        }
    }

    private func completionBadge(topic: String) -> some View {
        AppCard(style: .elevated) {
            VStack(spacing: AppSpacing.sm) {
                Text("🏆").font(.system(size: 56))
                Text("Mastered in 7 days").appFont(.h3)
                Text(topic).appFont(.bodySmall).foregroundStyle(Color.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
        }
    }

    private func dayRow(day: LearningDay, current: Int) -> some View {
        let isDone = day.isCompleted
        let isCurrent = day.dayIndex == current
        return Button { openDay = day } label: {
            AppCard {
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundStyle(isDone ? Color.success : (isCurrent ? Color.accent : Color.textMuted))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Day \(day.dayIndex)").appFont(.body).fontWeight(.semibold)
                        Text(isDone ? "Completed" : (isCurrent ? "Today's lesson" : "Not started"))
                            .appFont(.caption).foregroundStyle(Color.textMuted)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(Color.textMuted)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
