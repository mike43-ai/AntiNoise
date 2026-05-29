import SwiftUI

/// Shown to existing v1.0 users (onboarding already completed) who have no topic
/// packs yet — Daily Knowledge needs them before the daily feed works. New users
/// get the picker inside the onboarding flow instead, so this only ever fires
/// once for upgraders.
struct TopicPacksBackfillView: View {
    let uid: String
    let onDone: () -> Void
    @State private var selection: Set<TopicPack> = []

    var body: some View {
        TopicPacksSelectionView(
            selection: $selection,
            headline: "Pick your daily topics",
            subtitle: "New: 3 fresh articles a day. Choose up to 3 topics to start.",
            ctaTitle: "Save"
        ) {
            OnboardingStore.setTopicPacks(selection, uid: uid)
            Task { await UserProfileSyncService.syncSignals(uid: uid) }
            onDone()
        }
        .onAppear { selection = OnboardingStore.topicPacks(uid: uid) }
    }
}
