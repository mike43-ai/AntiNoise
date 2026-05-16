import SwiftUI

struct CaptureRowView: View {
    let capture: Capture
    let summary: Summary?

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: kindIcon)
                        .foregroundStyle(Color.textMuted)
                    if let scope = resolvedScope {
                        Chip(title: shortScope(scope), variant: .accent)
                    }
                    statusChip
                    Spacer()
                    Text(capture.capturedAt, format: .relative(presentation: .named))
                        .appFont(.caption)
                        .foregroundStyle(Color.textMuted)
                }

                if let title = primaryText {
                    Text(title)
                        .appFont(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(2)
                }

                if let teaser = summary?.simpleExplanation {
                    Text(teaser)
                        .appFont(.bodySmall)
                        .foregroundStyle(Color.textMuted)
                        .lineLimit(2)
                }
            }
        }
    }

    private var resolvedScope: ClassificationScope? {
        PriorityScorer.resolveScope(capture: capture, summary: summary)
    }

    private var primaryText: String? {
        switch capture.kind {
        case .url:   return capture.sourceURL
        case .text:  return capture.rawText
        case .image: return "Image capture"
        }
    }

    private var kindIcon: String {
        switch capture.kind {
        case .url:   return "link"
        case .text:  return "text.alignleft"
        case .image: return "photo"
        }
    }

    @ViewBuilder
    private var statusChip: some View {
        switch capture.status {
        case .queued:
            Chip(title: "Queued", variant: .neutral)
        case .processing:
            Chip(title: "Summarizing", variant: .accent)
        case .summarized:
            Chip(title: "Ready", variant: .success)
        case .failed:
            Chip(title: "Failed", variant: .danger)
        case .archived:
            EmptyView()
        }
    }

    private func shortScope(_ s: ClassificationScope) -> String {
        switch s {
        case .personal: return "Personal"
        case .work:     return "Work"
        case .business: return "Business"
        }
    }
}
