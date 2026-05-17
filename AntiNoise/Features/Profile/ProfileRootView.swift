import SwiftData
import SwiftUI

@MainActor
struct ProfileRootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthStore.self) private var auth
    @Environment(SubscriptionStore.self) private var subscription

    @State private var viewModel: ProfileViewModel?
    @State private var isAPIKeySheetPresented = false
    @State private var isGoalsSheetPresented = false
    @State private var isDeleteSheetPresented = false
    @State private var exportItems: ShareItemsBox?
    @State private var errorMessage: String?
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    userCard
                    subscriptionSection

                    if let viewModel {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Stats").appFont(.caption).textCase(.uppercase).foregroundStyle(Color.textMuted)
                            StatsGrid(stats: viewModel.stats)
                        }

                        if !viewModel.goalsCountByScope.isEmpty {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text("Goals").appFont(.caption).textCase(.uppercase).foregroundStyle(Color.textMuted)
                                goalsRow(viewModel: viewModel)
                            }
                        }
                    }

                    settingsSection
                    NotificationSettingsSection()
                    privacySection
                    accountSection
                }
                .padding(AppSpacing.xl)
            }
            .background(Color.bgPrimary)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $isAPIKeySheetPresented) { APIKeyEntryView() }
            .sheet(isPresented: $isGoalsSheetPresented) { GoalSetupView() }
            .sheet(isPresented: $isDeleteSheetPresented) { DeleteAccountFlowView() }
            .sheet(item: $exportItems) { box in ShareSheet(items: box.items) }
            .sheet(isPresented: $showPaywall) {
                PaywallSheetView(offering: subscription.currentOffering)
                    .onAppear { Telemetry.track(.paywallShown(trigger: .profileUpgrade)) }
            }
            .task {
                if viewModel == nil {
                    viewModel = ProfileViewModel(modelContext: modelContext)
                }
                if let uid = auth.currentUser?.id {
                    viewModel?.refresh(uid: uid)
                }
            }
            .alert("Export failed", isPresented: alertBinding, presenting: errorMessage) { _ in
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: { msg in
                Text(msg)
            }
        }
    }

    @ViewBuilder
    private var userCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(auth.currentUser?.displayName ?? "You").appFont(.h2)
                if let email = auth.currentUser?.email {
                    Text(email).appFont(.bodySmall).foregroundStyle(Color.textMuted)
                }
            }
        }
    }

    private func goalsRow(viewModel: ProfileViewModel) -> some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(ClassificationScope.allCases, id: \.self) { scope in
                let count = viewModel.goalsCountByScope[scope] ?? 0
                AppCard {
                    VStack(alignment: .leading, spacing: 2) {
                        Image(systemName: scope.systemImage).foregroundStyle(Color.accent)
                        Text(scope.title).appFont(.caption).foregroundStyle(Color.textMuted)
                        Text("\(count) / \(LearningGoalRepository.maxPerScope)").appFont(.body).fontWeight(.semibold)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var subscriptionSection: some View {
        if subscription.isPro {
            AppCard {
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Color.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Pro Member").appFont(.body).fontWeight(.semibold)
                        if case .active(let endsAt) = subscription.trialState {
                            Text("Trial ends \(endsAt.formatted(date: .abbreviated, time: .omitted))")
                                .appFont(.caption).foregroundStyle(Color.textMuted)
                        }
                    }
                    Spacer()
                }
            }
        } else {
            AppCard(style: .elevated) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Free plan").appFont(.bodySmall).fontWeight(.semibold)
                    Text("3 captures/day · 5 AI summaries/month")
                        .appFont(.caption).foregroundStyle(Color.textMuted)
                    PrimaryButton(title: "Upgrade to Pro", fullWidth: false) {
                        showPaywall = true
                    }
                }
            }
        }
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Settings").appFont(.caption).textCase(.uppercase).foregroundStyle(Color.textMuted)
            SecondaryButton(title: "Manage learning goals", systemImage: "target") {
                isGoalsSheetPresented = true
            }
            SecondaryButton(title: hasKey ? "Manage OpenAI key" : "Add OpenAI key", systemImage: "key") {
                isAPIKeySheetPresented = true
            }
            SecondaryButton(title: "Export my data", systemImage: "square.and.arrow.up") {
                exportAll()
            }
        }
    }

    private var privacySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Privacy").appFont(.caption).textCase(.uppercase).foregroundStyle(Color.textMuted)
            PrivacyConsentRow()
        }
        .padding(.top, AppSpacing.lg)
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Account").appFont(.caption).textCase(.uppercase).foregroundStyle(Color.textMuted)
            SecondaryButton(title: "Restore purchases", systemImage: "arrow.clockwise") {
                Task { await subscription.restorePurchases() }
            }
            SecondaryButton(title: "Sign out", systemImage: "rectangle.portrait.and.arrow.right") {
                try? auth.signOut()
            }
            GhostButton(title: "Delete account", systemImage: "trash", tint: .danger) {
                isDeleteSheetPresented = true
            }
        }
        .padding(.top, AppSpacing.lg)
    }

    private var hasKey: Bool {
        SecretStore.get(forKey: SecretStore.openAIAPIKey)?.isEmpty == false
    }

    private var alertBinding: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    private func exportAll() {
        guard let user = auth.currentUser else { return }
        do {
            let service = DataExportService(modelContainer: modelContext.container)
            let url = try service.exportAll(userID: user.id, email: user.email)
            exportItems = ShareItemsBox(items: [url])
            Telemetry.track(.accountExport)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    ProfileRootView()
        .environment(AuthStore())
        .environment(SubscriptionStore())
        .environment(PrivacyConsentStore())
        .environment(NotificationService())
}
