import SwiftUI

// Phase 07 replaces this placeholder with the real LearnHubView. Kept as a
// thin wrapper so MainTabView's switch doesn't have to change.
struct LearnRootView: View {
    var body: some View {
        LearnHubView()
    }
}

#Preview {
    LearnRootView()
        .environment(AuthStore())
        .environment(AppRouter())
}
