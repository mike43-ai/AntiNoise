import Observation
import SwiftUI

// Cross-tab navigation state. Lives at MainTabView scope so the entire
// signed-in surface can read/select tabs without prop-drilling.
@Observable
@MainActor
final class AppRouter {
    var selectedTab: AppTab = .home
    var isCaptureSheetPresented = false

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
