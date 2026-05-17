import SwiftData
import SwiftUI

struct CaptureFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(SummarizerHolder.self) private var summarizerHolder
    @Environment(ReachabilityObserver.self) private var reachability
    @Environment(AuthStore.self) private var auth
    @Environment(SubscriptionStore.self) private var subscription

    @State private var model: CaptureFlowModel?
    @State private var showQuotaSheet = false
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            Group {
                if let model {
                    content(model: model)
                } else {
                    AppLoadingIndicator()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.bgPrimary.ignoresSafeArea())
            .navigationTitle("Capture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .tint(Color.textPrimary)
                }
            }
            .task {
                if model == nil {
                    let holder = summarizerHolder
                    let reach = reachability
                    let authRef = auth
                    let subRef = subscription
                    model = CaptureFlowModel(
                        modelContext: modelContext,
                        summarizerProvider: { holder.summarizer },
                        isOnline: { reach.isOnline },
                        quotaUIDProvider: { authRef.currentUser?.id },
                        isProProvider: { subRef.isPro }
                    )
                }
            }
            .sheet(isPresented: $showQuotaSheet) {
                QuotaHitSheet(
                    kind: .capture,
                    offering: subscription.currentOffering,
                    onUpgrade: { showQuotaSheet = false; showPaywall = true },
                    onLater: {}
                )
                .onAppear { Telemetry.track(.paywallShown(trigger: .quotaCapture)) }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallSheetView(offering: subscription.currentOffering)
            }
        }
    }

    @ViewBuilder
    private func content(model: CaptureFlowModel) -> some View {
        @Bindable var bound = model

        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            modeSegmented(model: bound)

            switch bound.mode {
            case .url:   CaptureUrlInputView(text: $bound.urlText)
            case .note:  CaptureNoteInputView(text: $bound.noteText)
            case .image: CaptureImagePickerView(image: $bound.pickedImage)
            }

            if let err = bound.errorMessage {
                Text(err)
                    .appFont(.caption)
                    .foregroundStyle(Color.danger)
            }

            Spacer(minLength: AppSpacing.md)

            PrimaryButton(
                title: "Capture",
                isLoading: bound.isSaving,
                isDisabled: !bound.canSave
            ) {
                Task {
                    switch await bound.save() {
                    case .saved:        dismiss()
                    case .quotaExceeded: showQuotaSheet = true
                    case .failed:       break
                    }
                }
            }
        }
        .padding(.horizontal, AppSpacing.xl)
        .padding(.top, AppSpacing.lg)
        .padding(.bottom, AppSpacing.xl)
    }

    @ViewBuilder
    private func modeSegmented(model: CaptureFlowModel) -> some View {
        @Bindable var bound = model
        HStack(spacing: AppSpacing.sm) {
            ForEach(CaptureMode.allCases, id: \.self) { mode in
                modeChip(mode: mode, isSelected: bound.mode == mode) {
                    withAnimation(AppMotion.quick) { bound.mode = mode }
                }
            }
        }
    }

    private func modeChip(mode: CaptureMode, isSelected: Bool, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: mode.systemImage)
                Text(mode.title)
            }
            .appFont(.bodySmall)
            .fontWeight(.semibold)
            .foregroundStyle(isSelected ? .white : Color.textPrimary)
            .padding(.horizontal, AppSpacing.lg)
            .frame(minHeight: 40)
            .background(isSelected ? Color.textPrimary : Color.surface)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(isSelected ? Color.textPrimary : Color.appBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
