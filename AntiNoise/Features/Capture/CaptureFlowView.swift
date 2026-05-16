import SwiftData
import SwiftUI

struct CaptureFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(SummarizerHolder.self) private var summarizerHolder
    @Environment(ReachabilityObserver.self) private var reachability

    @State private var model: CaptureFlowModel?

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
                    // Capture holder by reference so a Phase-06 swap of
                    // `summarizerHolder.summarizer` propagates to in-flight captures.
                    let holder = summarizerHolder
                    let reach = reachability
                    model = CaptureFlowModel(
                        modelContext: modelContext,
                        summarizerProvider: { holder.summarizer },
                        isOnline: { reach.isOnline }
                    )
                }
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
                    let ok = await bound.save()
                    if ok { dismiss() }
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
