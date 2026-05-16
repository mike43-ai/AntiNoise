import SwiftUI

struct InboxListView: View {
    let captures: [Capture]
    let summaries: [UUID: Summary]
    let onSelect: (Capture) -> Void
    let onArchive: (UUID) -> Void

    var body: some View {
        if captures.isEmpty {
            AppEmptyState(
                systemImage: "tray",
                title: "Inbox is clear",
                message: "Captures land here as soon as you save them. Pull-to-refresh isn't needed — the list is live."
            )
            .padding(.top, AppSpacing.xxl)
        } else {
            VStack(spacing: AppSpacing.sm) {
                ForEach(captures) { capture in
                    Button { onSelect(capture) } label: {
                        CaptureRowView(capture: capture, summary: summaries[capture.id])
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button { onArchive(capture.id) } label: { Label("Archive", systemImage: "archivebox") }
                    }
                }
            }
        }
    }
}
