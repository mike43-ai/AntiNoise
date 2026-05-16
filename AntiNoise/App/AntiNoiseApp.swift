import FirebaseCore
import SwiftUI

@main
struct AntiNoiseApp: App {
    @State private var auth = AuthStore()

    init() {
        configureFirebaseIfPossible()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(auth)
                .task { auth.bootstrap() }
        }
    }

    private func configureFirebaseIfPossible() {
        guard FirebaseApp.app() == nil else { return }
        guard Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist") != nil else {
            #if DEBUG
            assertionFailure("""
                Missing GoogleService-Info.plist.
                Download from Firebase Console → Project Settings → iOS app
                and drop it into AntiNoise/Resources/.
                The .example.plist in the repo is a placeholder, not loaded by Firebase.
                """)
            #else
            print("[AntiNoise] GoogleService-Info.plist missing — auth disabled.")
            #endif
            return
        }
        FirebaseApp.configure()
    }
}
