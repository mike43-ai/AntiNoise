import Observation
import SwiftUI

// Cross-tab navigation state. Lives at MainTabView scope so the entire
// signed-in surface can read/select tabs without prop-drilling.
@Observable
@MainActor
final class AppRouter {
    var selectedTab: AppTab = .home
    var isCaptureSheetPresented = false

    // Set by an immersive screen (e.g. an active focus session) to hide the
    // bottom tab bar. Keeps full-screen content clear of the bar and prevents
    // tab-switching from tearing down a running session.
    var hideTabBar = false

    func selectTab(_ tab: AppTab) {
        if tab.isCenterAction {
            isCaptureSheetPresented = true
        } else {
            selectedTab = tab
        }
    }

    func presentCapture() {
        isCaptureSheetPresented = true
    }

    func dismissCapture() {
        isCaptureSheetPresented = false
    }
}
