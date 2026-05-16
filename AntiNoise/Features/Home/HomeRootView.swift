import SwiftUI

struct HomeRootView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.xl) {
                AppEmptyState(
                    systemImage: "house",
                    title: "Home",
                    message: "Your daily learning briefing lives here.\nPhase 10 fills this in.",
                    actionTitle: "Capture something",
                    action: { router.presentCapture() }
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.bgPrimary)
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    HomeRootView()
        .environment(AppRouter())
}
