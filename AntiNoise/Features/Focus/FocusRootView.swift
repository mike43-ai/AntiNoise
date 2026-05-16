import SwiftUI

struct FocusRootView: View {
    var body: some View {
        NavigationStack {
            VStack {
                AppEmptyState(
                    systemImage: "timer",
                    title: "Focus",
                    message: "Pomodoro sessions and deep-work blocks.\nPhase 09 fills this in."
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.bgPrimary)
            .navigationTitle("Focus")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview { FocusRootView() }
