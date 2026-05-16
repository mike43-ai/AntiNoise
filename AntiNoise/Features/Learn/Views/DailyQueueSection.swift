import SwiftUI

struct DailyQueueSection: View {
    let captures: [Capture]
    let summaries: [UUID: Summary]
    let onSelect: (Capture) -> Void
    let onMarkDone: (UUID) -> Void
    let onSkip: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Today's queue")
                    .appFont(.h3)
                Spacer()
                Text("\(captures.count) of 5")
                    .appFont(.caption)
                    .foregroundStyle(Color.textMuted)
            }

            if captures.isEmpty {
                AppCard(style: .outline) {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Nothing queued for today.")
                            .appFont(.body)
                        Text("Capture a link or a screenshot — items appear here once AI finishes summarizing.")
                            .appFont(.bodySmall)
                            .foregroundStyle(Color.textMuted)
                    }
                }
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(captures) { capture in
                        Button { onSelect(capture) } label: {
                            CaptureRowView(capture: capture, summary: summaries[capture.id])
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button { onMarkDone(capture.id) } label: { Label("Mark done", systemImage: "checkmark") }
                            Button { onSkip(capture.id) } label: { Label("Skip", systemImage: "forward") }
                        }
                    }
                }
            }
        }
    }
}

