import SwiftUI

struct MainTabView: View {
    @State private var router = AppRouter()

    var body: some View {
        @Bindable var bindableRouter = router

        tabContent
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.bgPrimary.ignoresSafeArea())
            .safeAreaInset(edge: .bottom, spacing: 0) {
                BottomTabBar(selection: tabSelectionBinding)
            }
            .environment(router)
            .sheet(isPresented: $bindableRouter.isCaptureSheetPresented) {
                CaptureFlowView()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch router.selectedTab {
        case .home:    HomeRootView()
        case .learn:   LearnRootView()
        case .focus:   FocusRootView()
        case .profile: ProfileRootView()
        case .capture: HomeRootView() // unreachable — capture opens modally via selectTab(_:)
        }
    }

    // Intercept selection so `.capture` opens a sheet instead of becoming the active tab.
    private var tabSelectionBinding: Binding<AppTab> {
        Binding(
            get: { router.selectedTab },
            set: { newValue in router.selectTab(newValue) }
        )
    }
}

#Preview {
    MainTabView()
        .environment(AuthStore())
}
