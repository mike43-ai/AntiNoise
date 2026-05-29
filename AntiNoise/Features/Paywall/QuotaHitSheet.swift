import RevenueCat
import SwiftUI

struct QuotaHitSheet: View {
    let kind: UsageKind
    let offering: Offering?
    let onUpgrade: () -> Void
    let onLater: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(Color.accent)
                Text(title).appFont(.h1).multilineTextAlignment(.leading)
                Text(message).appFont(.body).foregroundStyle(Color.textMuted)
                Spacer()
                VStack(spacing: AppSpacing.md) {
                    PrimaryButton(title: "See Pro plan") { onUpgrade() }
                    SecondaryButton(title: "Maybe later") {
                        onLater(); dismiss()
                    }
                }
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.bottom, AppSpacing.xl)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(Color.bgPrimary.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .tint(Color.textPrimary)
                }
            }
        }
    }

    private var title: String {
        switch kind {
        case .capture:   return "You've used today's free captures."
        case .aiSummary: return "You've used this month's free AI summaries."
        case .lesson:    return "You've used this month's free lessons."
        case .article:   return "You've seen today's free skills."
        }
    }

    private var message: String {
        switch kind {
        case .capture:
            return "Pro lifts the 3-per-day cap so you can capture every signal — including binges. Free quota resets at midnight."
        case .aiSummary:
            return "Pro lifts the 10/month cap and gives you unlimited Feynman summaries + flashcard generation."
        case .lesson:
            return "Pro lifts the 3-lessons/month cap so you can turn any capture or skill into layered flashcards. Free quota resets monthly."
        case .article:
            return "Pro unlocks more daily skills. Your free pick refreshes tomorrow."
        }
    }

    private var icon: String {
        switch kind {
        case .capture:   return "plus.rectangle.on.rectangle"
        case .aiSummary: return "sparkles"
        case .lesson:    return "rectangle.stack"
        case .article:   return "sparkles.rectangle.stack"
        }
    }
}
