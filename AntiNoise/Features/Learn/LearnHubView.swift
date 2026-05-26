import SwiftData
import SwiftUI

@MainActor
struct LearnHubView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthStore.self) private var auth
    @State private var model: LearnHubModel?
    @State private var navigationPath = NavigationPath()

    enum LearnDestination: Hashable {
        case capture(UUID)
        case deck(UUID)
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if let model {
                    content(model: model)
                } else {
                    AppLoadingIndicator()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(Color.bgPrimary)
            .navigationTitle("Learn")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: LearnDestination.self) { destination in
                switch destination {
                case .capture(let captureID):
                    SummaryDetailView(captureID: captureID)
                case .deck(let deckID):
                    DeckDetailView(deckID: deckID)
                }
            }
            .task {
                if model == nil {
                    let engine = DailyPriorityEngine(
                        modelContainer: modelContext.container,
                        userScopesProvider: { resolveUserScopes() }
                    )
                    model = LearnHubModel(modelContext: modelContext, priorityEngine: engine)
                }
                model?.refresh()
            }
        }
    }

    @ViewBuilder
    private func content(model: LearnHubModel) -> some View {
        @Bindable var bound = model

        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                tabSegmented(bound: bound)

                if bound.dueTodayCount > 0 {
                    dueCardsBanner(count: bound.dueTodayCount)
                        .padding(.horizontal, AppSpacing.xl)
                }

                switch bound.tab {
                case .today:
                    DailyQueueSection(
                        captures: bound.dailyQueue,
                        summaries: bound.summariesByID,
                        onSelect: { capture in navigationPath.append(LearnDestination.capture(capture.id)) },
                        onMarkDone: { bound.markDone(captureID: $0) },
                        onSkip: { bound.markSkipped(captureID: $0) }
                    )
                    .padding(.horizontal, AppSpacing.xl)
                case .inbox:
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        ScopeFilterChips(selection: $bound.scopeFilter)
                        InboxListView(
                            captures: bound.filteredInbox(),
                            summaries: bound.summariesByID,
                            onSelect: { capture in navigationPath.append(LearnDestination.capture(capture.id)) },
                            onArchive: { bound.archive(captureID: $0) }
                        )
                        .padding(.horizontal, AppSpacing.xl)
                    }
                case .decks:
                    DeckListView(onSelect: { deckID in
                        navigationPath.append(LearnDestination.deck(deckID))
                    })
                    .padding(.horizontal, AppSpacing.xl)
                }
            }
            .padding(.vertical, AppSpacing.lg)
        }
        .contentMargins(.bottom, BottomTabBar.contentHeight, for: .scrollContent)
        .refreshable { bound.refresh() }
    }

    private func tabSegmented(bound: LearnHubModel) -> some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(LearnHubTab.allCases) { tab in
                Button {
                    withAnimation(AppMotion.quick) { bound.tab = tab }
                } label: {
                    Text(tab.title)
                        .appFont(.bodySmall)
                        .fontWeight(.semibold)
                        .foregroundStyle(bound.tab == tab ? .white : Color.textPrimary)
                        .padding(.horizontal, AppSpacing.lg)
                        .frame(minHeight: 40)
                        .background(bound.tab == tab ? Color.textPrimary : Color.surface)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(bound.tab == tab ? Color.textPrimary : Color.appBorder, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, AppSpacing.xl)
    }

    private func dueCardsBanner(count: Int) -> some View {
        AppCard(style: .elevated) {
            HStack {
                Image(systemName: "bell.badge.fill").foregroundStyle(Color.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(count) card\(count == 1 ? "" : "s") due today").appFont(.body).fontWeight(.semibold)
                    Text("Tap Decks to start a review session.").appFont(.caption).foregroundStyle(Color.textMuted)
                }
                Spacer()
            }
        }
    }

    private func resolveUserScopes() -> Set<ClassificationScope> {
        guard let uid = auth.currentUser?.id else { return [] }
        return OnboardingStore.scopes(uid: uid)
    }
}
