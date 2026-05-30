import SwiftData
import SwiftUI

/// Learn-hub surface for Deep Learn: shows the active course's progress (tap to
/// continue) or a short explainer when there's none. Starting a course happens
/// from a deck (see DeepLearnStartButton).
@MainActor
struct DeepLearnSection: View {
    let onOpenPath: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var active: LearningPath?
    @State private var current: Int = 1

    var body: some View {
        Group {
            if let active {
                Button(action: onOpenPath) {
                    AppCard(style: .elevated) {
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: "graduationcap.fill")
                                .font(.system(size: 28)).foregroundStyle(Color.accent)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(active.topic).appFont(.body).fontWeight(.semibold).lineLimit(1)
                                Text("Deep Learn · Day \(min(current, active.durationDays))/\(active.durationDays)")
                                    .appFont(.caption).foregroundStyle(Color.textMuted)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(Color.textMuted)
                        }
                    }
                }
                .buttonStyle(.plain)
            } else {
                AppCard {
                    HStack(spacing: AppSpacing.md) {
                        Image(systemName: "graduationcap")
                            .font(.system(size: 28)).foregroundStyle(Color.textMuted)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Deep Learn").appFont(.body).fontWeight(.semibold)
                            Text("Open a deck to start a 7-day mastery course.")
                                .appFont(.caption).foregroundStyle(Color.textMuted)
                        }
                        Spacer()
                    }
                }
            }
        }
        .task { reload() }
    }

    private func reload() {
        let store = LearningPathStore(context: modelContext)
        active = store.fetchActivePath()
        if let active { current = store.days(for: active.id).first(where: { $0.completedAt == nil })?.dayIndex ?? active.durationDays }
    }
}
