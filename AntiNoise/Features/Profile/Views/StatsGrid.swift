import SwiftUI

struct StatsGrid: View {
    let stats: DashboardStats

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.sm) {
            cell(value: "\(stats.capturesTotal)", label: "Captures")
            cell(value: "\(stats.summariesTotal)", label: "Summaries")
            cell(value: "\(stats.dueCardsCount)", label: "Cards due")
            cell(value: "\(stats.streakDays)", label: "Day streak")
        }
    }

    private func cell(value: String, label: String) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: 0) {
                Text(value).appFont(.h2)
                Text(label).appFont(.caption).foregroundStyle(Color.textMuted).textCase(.uppercase)
            }
        }
    }
}
