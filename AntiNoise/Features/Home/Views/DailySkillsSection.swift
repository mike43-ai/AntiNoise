import SwiftUI

/// "Today's skills" — 3 curated skills to learn, from the backend daily pipeline.
/// Study this → Feynman summary or flashcards; Learn more → web search.
@MainActor
struct DailySkillsSection: View {
    @Bindable var model: DailySkillsModel
    @Environment(\.openURL) private var openURL
    @State private var studyTarget: DailySkillItem?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("Today's skills").appFont(.h3)
                Spacer()
                Button {
                    Task { await model.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(Color.textMuted)
                }
                .disabled(model.state == .loading || model.isStudying)
            }

            content
        }
        .confirmationDialog(
            "Study this skill",
            isPresented: studyDialogBinding,
            titleVisibility: .visible,
            presenting: studyTarget
        ) { item in
            Button("Read summary (Feynman)") { Task { await model.study(item, mode: .feynman) } }
            Button("Study flashcards") { Task { await model.study(item, mode: .flashcards) } }
            Button("Cancel", role: .cancel) {}
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .loading:
            AppCard(style: .outline) {
                HStack(spacing: AppSpacing.md) {
                    AppLoadingIndicator(size: 20)
                    Text("Picking today's skills…").appFont(.bodySmall).foregroundStyle(Color.textMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        case .caughtUp:
            infoCard("You're caught up 🎉", "No new skills today — review your cards in Learn.")
        case .noProfile:
            infoCard("Pick your topics", "Choose topic packs to get daily skills tailored to you.")
        case .error(let message):
            AppCard(style: .outline) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Couldn't load skills").appFont(.body)
                    Text(message).appFont(.caption).foregroundStyle(Color.textMuted)
                    GhostButton(title: "Retry", systemImage: "arrow.clockwise") {
                        Task { await model.refresh() }
                    }
                }
            }
        case .idle:
            if model.items.isEmpty {
                infoCard("You're caught up 🎉", "No new skills today — review your cards in Learn.")
            } else {
                ForEach(model.items) { item in
                    skillCard(item)
                }
            }
        }
    }

    private func skillCard(_ item: DailySkillItem) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(item.keyword.uppercased())
                    .appFont(.caption)
                    .foregroundStyle(Color.accent)
                Text(item.title).appFont(.body).fontWeight(.semibold)
                Text(item.whyNow).appFont(.bodySmall).foregroundStyle(Color.textMuted)

                HStack(spacing: AppSpacing.sm) {
                    PrimaryButton(title: item.studiedDeckID == nil ? "Study this" : "Open", fullWidth: false) {
                        studyTarget = item
                    }
                    GhostButton(title: "Learn more", systemImage: "safari") {
                        openSearch(item.suggestedSearch)
                    }
                    Spacer()
                    Button {
                        model.skip(item)
                    } label: {
                        Image(systemName: "xmark").foregroundStyle(Color.textMuted)
                    }
                }
            }
        }
        .opacity(model.isStudying ? 0.6 : 1)
        .disabled(model.isStudying)
    }

    private func infoCard(_ title: String, _ subtitle: String) -> some View {
        AppCard(style: .outline) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title).appFont(.body)
                Text(subtitle).appFont(.bodySmall).foregroundStyle(Color.textMuted)
            }
        }
    }

    private var studyDialogBinding: Binding<Bool> {
        Binding(get: { studyTarget != nil }, set: { if !$0 { studyTarget = nil } })
    }

    private func openSearch(_ query: String) {
        let q = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        if let url = URL(string: "https://www.google.com/search?q=\(q)") {
            openURL(url)
        }
    }
}
