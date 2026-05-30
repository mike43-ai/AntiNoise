import SwiftUI

struct TodaySnapshotCard: View {
    let stats: DashboardStats

    var body: some View {
        AppCard(style: .elevated) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Today")
                    .appFont(.caption)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.textMuted)

                HStack(alignment: .top, spacing: AppSpacing.lg) {
                    stat(value: stats.capturesToday, label: "captured")
                    stat(value: stats.dueCardsCount, label: "cards due")
                    stat(value: stats.streakDays, label: "day streak")
                }
            }
        }
    }

    private func stat(value: Int, label: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(value)").appFont(.h1)
            Text(label).appFont(.caption).foregroundStyle(Color.textMuted).textCase(.uppercase)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
