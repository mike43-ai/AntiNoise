import SwiftUI

struct LearnRootView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        NavigationStack {
            VStack {
                AppEmptyState(
                    systemImage: "book",
                    title: "Learn",
                    message: "Flashcards, deep-dives, and your daily review queue land here.\nPhase 08 fills this in.",
                    actionTitle: "Capture something",
                    action: { router.presentCapture() }
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.bgPrimary)
            .navigationTitle("Learn")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    LearnRootView()
        .environment(AppRouter())
}
