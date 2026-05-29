import SwiftData
import SwiftUI

@MainActor
struct HomeRootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthStore.self) private var auth
    @Environment(AppRouter.self) private var router
    @Environment(SummarizerHolder.self) private var summarizerHolder
    @Environment(ReachabilityObserver.self) private var reachability
    @Environment(SubscriptionStore.self) private var subscription
    @State private var model: HomeViewModel?
    @State private var skillsModel: DailySkillsModel?
    @State private var navigationPath = NavigationPath()

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
            .navigationTitle(greeting)
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: UUID.self) { captureID in
                SummaryDetailView(captureID: captureID)
            }
            .navigationDestination(for: DeckRoute.self) { route in
                DeckDetailView(deckID: route.id)
            }
            .task {
                if model == nil {
                    model = HomeViewModel(
                        modelContext: modelContext,
                        userScopesProvider: { resolveUserScopes() }
                    )
                }
                if skillsModel == nil {
                    let holder = summarizerHolder
                    let reach = reachability
                    let authRef = auth
                    let subRef = subscription
                    skillsModel = DailySkillsModel(
                        modelContext: modelContext,
                        aiClient: AIClient(isProProvider: { subRef.isPro }),
                        summarizerProvider: { holder.summarizer },
                        cardGenerator: CardGenerator(
                            modelContainer: modelContext.container,
                            isOnline: { reach.isOnline },
                            isProProvider: { subRef.isPro }
                        ),
                        uidProvider: { authRef.currentUser?.id },
                        isProProvider: { subRef.isPro }
                    )
                }
                if let uid = auth.currentUser?.id {
                    SeedDeckRepository.seedIfNeeded(uid: uid, context: modelContext)
                }
                model?.refresh()
                await skillsModel?.loadOnAppear()
            }
            .onChange(of: skillsModel?.studyCaptureID) { _, _ in
                if let captureID = skillsModel?.studyCaptureID {
                    navigationPath.append(captureID)
                    skillsModel?.studyCaptureID = nil
                }
            }
            .onChange(of: skillsModel?.studyDeckRoute) { _, _ in
                if let route = skillsModel?.studyDeckRoute {
                    navigationPath.append(route)
                    skillsModel?.studyDeckRoute = nil
                }
            }
        }
    }

    @ViewBuilder
    private func content(model: HomeViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                TodaySnapshotCard(stats: model.stats)
                if let skillsModel {
                    DailySkillsSection(model: skillsModel)
                }
                queueSection(model: model)
                ctaSection
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.lg)
        }
        .contentMargins(.bottom, BottomTabBar.contentHeight, for: .scrollContent)
        .refreshable { model.refresh() }
    }

    private func queueSection(model: HomeViewModel) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("Up next").appFont(.h3)
                Spacer()
                if !model.queuePreview.isEmpty {
                    GhostButton(title: "See all", systemImage: "chevron.right") {
                        router.selectTab(.learn)
                    }
                }
            }

            if model.queuePreview.isEmpty {
                AppCard(style: .outline) {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Nothing queued.").appFont(.body)
                        Text("Capture a link or screenshot — it'll appear here once AI summarizes.")
                            .appFont(.bodySmall)
                            .foregroundStyle(Color.textMuted)
                    }
                }
            } else {
                ForEach(model.queuePreview) { capture in
                    Button {
                        navigationPath.append(capture.id)
                    } label: {
                        CaptureRowView(capture: capture, summary: model.summariesByID[capture.id])
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var ctaSection: some View {
        VStack(spacing: AppSpacing.sm) {
            PrimaryButton(title: "Start a focus session", systemImage: "timer") {
                router.selectTab(.focus)
            }
            SecondaryButton(title: "Capture something new", systemImage: "plus") {
                router.presentCapture()
            }
        }
        .padding(.top, AppSpacing.md)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = auth.currentUser?.displayName?.split(separator: " ").first.map(String.init) ?? "there"
        switch hour {
        case 5..<12:  return "Morning, \(name)"
        case 12..<17: return "Afternoon, \(name)"
        case 17..<22: return "Evening, \(name)"
        default:      return "Hey, \(name)"
        }
    }

    private func resolveUserScopes() -> Set<ClassificationScope> {
        guard let uid = auth.currentUser?.id else { return [] }
        return OnboardingStore.scopes(uid: uid)
    }
}

#Preview {
    HomeRootView()
        .environment(AuthStore())
        .environment(AppRouter())
}
