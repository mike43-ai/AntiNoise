import SwiftData
import SwiftUI

@MainActor
struct FocusRootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppRouter.self) private var router
    @State private var engine: FocusSessionEngine?
    @State private var navigateToDeckID: UUID?
    @State private var lastPlannedSeconds: Int = 0
    @State private var lastTargetID: UUID?

    var body: some View {
        NavigationStack {
            Group {
                if let engine {
                    body(engine: engine)
                } else {
                    AppLoadingIndicator()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(Color.bgPrimary.ignoresSafeArea())
            .navigationTitle("Focus")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(item: $navigateToDeckID) { deckID in
                FlashcardReviewView(deckID: deckID)
            }
            .task {
                if engine == nil {
                    engine = FocusSessionEngine(modelContainer: modelContext.container)
                }
                await engine?.requestNotificationPermissionIfNeeded()
            }
            .onChange(of: engine?.state) { _, newState in
                // Hide the tab bar whenever a session is active (running, paused,
                // or result) so the full-screen controls aren't covered by the
                // bar and switching tabs can't tear down a live session.
                router.hideTabBar = (newState ?? .idle) != .idle
            }
        }
    }

    @ViewBuilder
    private func body(engine: FocusSessionEngine) -> some View {
        switch engine.state {
        case .idle:
            FocusSetupView { duration, kind, id, label in
                lastPlannedSeconds = duration
                lastTargetID = (kind == .deck) ? id : nil
                engine.start(durationSeconds: duration, targetKind: kind, targetID: id, targetLabel: label)
            }
        case .running, .paused:
            FocusActiveView(
                engine: engine,
                targetLabel: engine.lastTargetLabel,
                onEnd: { /* engine.state will flip to .finished */ }
            )
            .navigationBarHidden(true)
        case .finished(let completed):
            FocusResultView(
                plannedSeconds: lastPlannedSeconds,
                elapsedSeconds: engine.lastElapsedSeconds,
                completed: completed,
                linkedDeckID: lastTargetID,
                onReview: { deckID in
                    navigateToDeckID = deckID
                    resetEngine()
                },
                onDone: { resetEngine() }
            )
        }
    }

    private func resetEngine() {
        engine = FocusSessionEngine(modelContainer: modelContext.container)
        lastTargetID = nil
        lastPlannedSeconds = 0
    }
}

#Preview {
    FocusRootView()
}
