import FirebaseCore
import SwiftData
import SwiftUI

@main
struct AntiNoiseApp: App {
    @State private var auth = AuthStore()
    @State private var subscription = SubscriptionStore()
    @State private var consent = PrivacyConsentStore()
    @State private var notifications = NotificationService()
    @State private var reachability = ReachabilityObserver()
    @State private var summarizerHolder = SummarizerHolder(summarizer: NoopSummarizerService())
    @State private var drainService: DrainQueueService?
    @State private var pendingJobs: PendingJobQueue?

    @Environment(\.scenePhase) private var scenePhase

    init() {
        configureFirebaseIfPossible()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(auth)
                .environment(subscription)
                .environment(consent)
                .environment(notifications)
                .environment(reachability)
                .environment(summarizerHolder)
                .modelContainer(PersistenceContainer.shared)
                .task {
                    bootstrap()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    handleScenePhase(newPhase)
                }
                .onChange(of: auth.state) { _, newState in
                    switch newState {
                    case .signedIn(let user):
                        Telemetry.setUserID(user.id)
                        Task { await subscription.signedIn(uid: user.id) }
                    case .signedOut:
                        Telemetry.setUserID(nil)
                        Task { await subscription.signedOut() }
                    case .unknown:
                        break
                    }
                }
        }
    }

    private func bootstrap() {
        Telemetry.attach(consent)
        consent.apply()
        notifications.bootstrap()
        auth.bootstrap()
        subscription.bootstrap()
        reachability.start()

        let container = PersistenceContainer.shared
        let reach = reachability
        let authStore = auth
        let subStore = subscription

        let summarizer = AISummarizer(
            modelContainer: container,
            userScopesProvider: {
                if let uid = authStore.currentUser?.id {
                    return OnboardingStore.scopes(uid: uid)
                }
                return []
            },
            uidProvider: { authStore.currentUser?.id },
            isOnline: { reach.isOnline },
            isProProvider: { subStore.isPro }
        )
        summarizerHolder.summarizer = summarizer

        let drain = DrainQueueService(modelContainer: container, summarizer: summarizer)
        drainService = drain
        drain.start()
        Task {
            await drain.drainNow()
            drain.cleanupOrphanedBlobs()
        }

        let jobs = PendingJobQueue(modelContainer: container, summarizer: summarizer)
        pendingJobs = jobs

        reachability.onChange = { online in
            if online {
                Task { await jobs.drain() }
            }
        }
    }

    private func handleScenePhase(_ phase: ScenePhase) {
        guard phase == .active else { return }
        Task { await drainService?.drainNow() }
    }

    private func configureFirebaseIfPossible() {
        guard FirebaseApp.app() == nil else { return }
        guard Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist") != nil else {
            #if DEBUG
            assertionFailure("""
                Missing GoogleService-Info.plist.
                Download from Firebase Console → Project Settings → iOS app
                and drop it into AntiNoise/Resources/.
                """)
            #else
            print("[AntiNoise] GoogleService-Info.plist missing — auth disabled.")
            #endif
            return
        }
        FirebaseApp.configure()
    }
}
