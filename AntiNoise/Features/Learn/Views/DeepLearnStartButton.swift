import SwiftData
import SwiftUI

/// Entry point to start a Deep Learn course from a specific deck. Deep Learn is
/// Pro-only: a free user tapping this gets the paywall and no network call (the
/// server also rejects non-pro as defense in depth). An already-started course
/// stays openable even if the user later downgrades. Enforces one active path.
@MainActor
struct DeepLearnStartButton: View {
    let deck: Deck

    @Environment(\.modelContext) private var modelContext
    @Environment(AuthStore.self) private var auth
    @Environment(SubscriptionStore.self) private var subscription
    @State private var model: DeepLearnModel?
    @State private var navigate = false
    @State private var showBusyAlert = false
    @State private var showPaywall = false

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            PrimaryButton(
                title: "Start Deep Learn · 7 days",
                systemImage: "graduationcap.fill",
                isLoading: model?.isWorking == true
            ) {
                Task { await start() }
            }
            if let error = model?.errorMessage {
                Text(error).appFont(.caption).foregroundStyle(Color.danger)
            }
        }
        .navigationDestination(isPresented: $navigate) { LearningPathView() }
        .alert("Finish your current course first", isPresented: $showBusyAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You can run one Deep Learn course at a time. Complete or abandon it before starting another.")
        }
        .sheet(isPresented: $showPaywall) {
            PaywallSheetView(offering: subscription.currentOffering)
                .onAppear { Telemetry.track(.paywallShown(trigger: .deepLearn)) }
        }
        .task { ensureModel() }
    }

    private func ensureModel() {
        guard model == nil else { return }
        let authRef = auth, subRef = subscription
        model = DeepLearnModel(
            modelContext: modelContext,
            client: AIClient(isProProvider: { subRef.isPro }),
            uidProvider: { authRef.currentUser?.id }
        )
        model?.refresh()
    }

    private func start() async {
        ensureModel()
        guard let model else { return }
        model.refresh()
        if let active = model.activePath, active.deckID != deck.id {
            showBusyAlert = true
            return
        }
        if model.activePath?.deckID == deck.id {
            navigate = true // resume existing course for this deck (open even if now free)
            return
        }
        // Starting a NEW course is Pro-only — gate before any network call.
        guard subscription.isPro else {
            showPaywall = true
            return
        }
        let uid = auth.currentUser?.id ?? ""
        // Snippet-mining from the user's captures is deferred; the backend handles
        // the cold-start (no snippets) case by generating a standard progression.
        await model.startPath(
            deck: deck,
            role: OnboardingStore.role(uid: uid)?.rawValue,
            level: OnboardingStore.experienceLevel(uid: uid)?.rawValue,
            snippets: []
        )
        if model.activePath != nil && model.errorMessage == nil {
            navigate = true
        }
    }
}
