import SwiftUI

@MainActor
struct MainTabView: View {
    @State private var router = AppRouter()

    var body: some View {
        @Bindable var bindableRouter = router

        mainSurface
            .background(Color.bgPrimary.ignoresSafeArea())
            .environment(router)
            .sheet(isPresented: $bindableRouter.isCaptureSheetPresented) {
                CaptureFlowView()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
    }

    // Show/hide the bar via an outer branch, not a conditional *inside*
    // `safeAreaInset`: a conditional placed directly in the inset makes SwiftUI
    // draw the bar while reserving zero inset height, and an immersive lesson
    // needs the inset gone entirely for true full-screen. This inset does not cross
    // into each tab's own NavigationStack, so scrollable roots additionally
    // clear the bar via `contentMargins(.bottom, BottomTabBar.contentHeight)`.
    @ViewBuilder
    private var mainSurface: some View {
        if router.hideTabBar {
            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            tabContent
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    BottomTabBar(selection: tabSelectionBinding)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch router.selectedTab {
        case .home:    HomeRootView()
        case .learn:   LearnRootView()
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
