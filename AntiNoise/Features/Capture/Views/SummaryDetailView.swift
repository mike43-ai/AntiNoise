import SwiftData
import SwiftUI

struct SummaryDetailView: View {
    let captureID: UUID

    @Environment(\.modelContext) private var modelContext
    @Environment(SummarizerHolder.self) private var summarizerHolder
    @State private var model: SummaryDetailModel?
    @State private var isScopeSheetPresented = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                if let model {
                    body(model: model)
                } else {
                    AppLoadingIndicator()
                        .frame(maxWidth: .infinity)
                        .padding(.top, AppSpacing.xxl)
                }
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.lg)
        }
        .background(Color.bgPrimary.ignoresSafeArea())
        .navigationTitle("Summary")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if model == nil {
                let holder = summarizerHolder
                model = SummaryDetailModel(
                    captureID: captureID,
                    modelContext: modelContext,
                    summarizerProvider: { holder.summarizer }
                )
            }
            model?.load()
        }
    }

    @ViewBuilder
    private func body(model: SummaryDetailModel) -> some View {
        if let summary = model.summary {
            sections(for: summary)
        } else if let capture = model.capture {
            statusView(capture: capture, model: model)
        } else {
            AppEmptyState(
                systemImage: "questionmark.circle",
                title: "Couldn't find this capture",
                message: "It may have been deleted."
            )
        }
    }

    @ViewBuilder
    private func sections(for summary: Summary) -> some View {
        let resolvedScope: ClassificationScope = model?.effectiveScope ?? summary.suggestedClassification
        HStack(spacing: AppSpacing.xs) {
            Button { isScopeSheetPresented = true } label: {
                Chip(title: shortScope(resolvedScope).uppercased(), variant: .accent, isSelected: false)
            }
            .buttonStyle(.plain)
            if model?.capture?.userClassification == nil {
                Text("· AI suggested")
                    .appFont(.caption)
                    .foregroundStyle(Color.textMuted)
            } else {
                Text("· you picked")
                    .appFont(.caption)
                    .foregroundStyle(Color.textMuted)
            }
        }
        .sheet(isPresented: $isScopeSheetPresented) {
            scopePickerSheet(current: resolvedScope)
                .presentationDetents([.medium])
        }

        section(title: "Simple explanation", body: summary.simpleExplanation)
        section(title: "Analogy", body: summary.analogy)
        listSection(title: "Knowledge gaps", items: summary.knowledgeGaps)
        listSection(title: "Examples", items: summary.examples)
        section(title: "Go deeper", body: summary.deeperQuestion)

        if summary.recommendDeepDive {
            AppCard(style: .elevated) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Recommended for deep-dive").appFont(.bodySmall).fontWeight(.semibold)
                    Text("Generate flash cards to lock this in.")
                        .appFont(.caption)
                        .foregroundStyle(Color.textMuted)
                    PrimaryButton(title: "Create flash cards", fullWidth: false) {
                        // Wired in Phase 08.
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func statusView(capture: Capture, model: SummaryDetailModel) -> some View {
        switch capture.status {
        case .queued:
            AppEmptyState(
                systemImage: "hourglass",
                title: "Waiting to summarize",
                message: "We'll process this when you're back online."
            )
        case .processing:
            VStack(spacing: AppSpacing.md) {
                AppLoadingIndicator()
                Text("Summarizing…").appFont(.bodySmall).foregroundStyle(Color.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, AppSpacing.xl)
        case .failed:
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Summary failed").appFont(.h3)
                if let err = capture.lastError {
                    Text(err).appFont(.bodySmall).foregroundStyle(Color.textMuted)
                }
                PrimaryButton(title: "Try again", isLoading: model.isRetrying) {
                    Task { await model.retry() }
                }
            }
        case .summarized, .archived:
            AppEmptyState(systemImage: "doc.text", title: capture.status.displayName)
        }
    }

    private func section(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title).appFont(.caption).textCase(.uppercase).foregroundStyle(Color.textMuted)
            Text(body).appFont(.body).foregroundStyle(Color.textPrimary)
        }
    }

    private func scopePickerSheet(current: ClassificationScope) -> some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Change classification")
                    .appFont(.h3)
                ForEach(ClassificationScope.allCases, id: \.self) { scope in
                    Button {
                        model?.overrideClassification(scope)
                        isScopeSheetPresented = false
                    } label: {
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: scope.systemImage)
                                .foregroundStyle(scope == current ? Color.accent : Color.textMuted)
                            VStack(alignment: .leading) {
                                Text(scope.title).appFont(.body).fontWeight(.semibold)
                                Text(scope.subtitle).appFont(.caption).foregroundStyle(Color.textMuted)
                            }
                            Spacer()
                            if scope == current {
                                Image(systemName: "checkmark").foregroundStyle(Color.accent)
                            }
                        }
                        .padding(AppSpacing.md)
                        .frame(maxWidth: .infinity)
                        .background(Color.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                .stroke(Color.appBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
                if model?.capture?.userClassification != nil {
                    GhostButton(title: "Reset to AI suggestion") {
                        model?.overrideClassification(nil)
                        isScopeSheetPresented = false
                    }
                }
                Spacer()
            }
            .padding(AppSpacing.xl)
            .background(Color.bgPrimary.ignoresSafeArea())
        }
    }

    private func shortScope(_ s: ClassificationScope) -> String {
        switch s {
        case .personal: return "Personal"
        case .work:     return "Work"
        case .business: return "Business"
        }
    }

    @ViewBuilder
    private func listSection(title: String, items: [String]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(title).appFont(.caption).textCase(.uppercase).foregroundStyle(Color.textMuted)
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                        HStack(alignment: .top, spacing: AppSpacing.sm) {
                            Text("•").appFont(.body).foregroundStyle(Color.textMuted)
                            Text(item).appFont(.body).foregroundStyle(Color.textPrimary)
                        }
                    }
                }
            }
        }
    }
}
