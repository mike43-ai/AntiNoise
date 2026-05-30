import SwiftUI

struct TodaySnapshotCard: View {
    let stats: DashboardStats

    @State private var revealed = false

    private var hasStreak: Bool { stats.streakDays > 0 }

    var body: some View {
        AppCard(style: .elevated) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text("Today")
                    .appFont(.caption)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.textMuted)

                streakHero

                HStack(alignment: .top, spacing: AppSpacing.lg) {
                    secondaryStat(value: stats.capturesToday, label: "captured")
                    secondaryStat(value: stats.dueCardsCount, label: "cards due")
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { revealed = true }
        }
    }

    private var streakHero: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: hasStreak ? "flame.fill" : "flame")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(hasStreak ? Color.accent : Color.textMuted)
                .scaleEffect(revealed ? 1 : 0.6)

            HStack(alignment: .firstTextBaseline, spacing: AppSpacing.xs) {
                Text("\(revealed ? stats.streakDays : 0)")
                    .appFont(.display)
                    .foregroundStyle(hasStreak ? Color.accent : Color.textPrimary)
                    .contentTransition(.numericText(value: Double(revealed ? stats.streakDays : 0)))
                Text("day streak")
                    .appFont(.caption)
                    .foregroundStyle(Color.textMuted)
            }
        }
    }

    private func secondaryStat(value: Int, label: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(value)").appFont(.h2)
            Text(label).appFont(.caption).foregroundStyle(Color.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
