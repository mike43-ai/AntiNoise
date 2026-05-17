import SwiftUI

@MainActor
struct FocusActiveView: View {
    @Bindable var engine: FocusSessionEngine
    let targetLabel: String?
    let onEnd: () -> Void

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            VStack(spacing: AppSpacing.xs) {
                if let targetLabel {
                    Chip(title: targetLabel.uppercased(), variant: .accent)
                }
                Text(FocusSessionEngine.formatRemaining(engine.remainingSeconds))
                    .font(.system(size: 96, weight: .light, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(Color.textPrimary)
                Text(stateLabel)
                    .appFont(.caption)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.textMuted)
            }

            Spacer()

            controlRow
                .padding(.horizontal, AppSpacing.xl)
                .padding(.bottom, AppSpacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bgPrimary.ignoresSafeArea())
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { engine.refresh() }
        }
        .onAppear { engine.reassertScreenOnIfNeeded() }
        .onDisappear { engine.releaseScreenOn() }
    }

    private var stateLabel: String {
        switch engine.state {
        case .running:  return "Focusing"
        case .paused:   return "Paused"
        case .finished: return "Done"
        case .idle:     return ""
        }
    }

    private var controlRow: some View {
        HStack(spacing: AppSpacing.md) {
            SecondaryButton(title: "End", systemImage: "stop.fill") {
                engine.abort()
                onEnd()
            }
            if engine.state == .paused {
                PrimaryButton(title: "Resume", systemImage: "play.fill") { engine.resume() }
            } else {
                PrimaryButton(title: "Pause", systemImage: "pause.fill") { engine.pause() }
            }
        }
    }
}
