import Foundation
import Observation
import SwiftData

/// Cached 7-day outline (one sub-topic + objective per day) produced at opt-in.
struct LearningOutline: Codable, Sendable {
    struct Day: Codable, Sendable {
        let day: Int
        let subtopic: String
        let objective: String
    }
    let days: [Day]
}

/// Owns the Deep Learn course lifecycle for the Learn tab: create a path (outline
/// + Day 1), lazily expand later days, and persist generated cards into the
/// shared SRS deck. Local SwiftData is the source of truth; Firestore is mirrored
/// best-effort. Pro-gating happens at the entry CTA (phase 05) and server-side.
@Observable
@MainActor
final class DeepLearnModel {
    var activePath: LearningPath?
    var days: [LearningDay] = []
    var isWorking = false
    var errorMessage: String?

    private let modelContext: ModelContext
    private let store: LearningPathStore
    private let client: AIClient
    private let uidProvider: () -> String?

    init(modelContext: ModelContext, client: AIClient, uidProvider: @escaping () -> String?) {
        self.modelContext = modelContext
        self.store = LearningPathStore(context: modelContext)
        self.client = client
        self.uidProvider = uidProvider
    }

    func refresh() {
        activePath = store.fetchActivePath()
        days = activePath.map { store.days(for: $0.id) } ?? []
    }

    /// Index (1-based) of the first not-completed day, else durationDays.
    var currentDayIndex: Int {
        days.first(where: { $0.completedAt == nil })?.dayIndex ?? (activePath?.durationDays ?? 1)
    }

    // MARK: - Create

    func startPath(deck: Deck, role: String?, level: String?, snippets: [String]) async {
        guard store.fetchActivePath() == nil else { return } // 1 active path rule
        isWorking = true; errorMessage = nil
        defer { isWorking = false }
        do {
            let res = try await client.startLearningPath(
                topic: deck.title, deckTitle: deck.title, captureSnippets: snippets, role: role, level: level
            )
            let path = store.createPath(deckID: deck.id, topic: deck.title, outlineJSON: res.outlineJSON)
            fillDay(path: path, dayIndex: 1, concept: res.day1.concept, applyPrompt: res.day1.applyPrompt, cards: res.day1.cards)
            Telemetry.track(.learnPathStarted(topic: deck.title))
            if let uid = uidProvider() { await LearningPathSyncService.mirror(path, uid: uid) }
            refresh()
        } catch {
            errorMessage = (error as? AIClient.ClientError)?.errorDescription ?? error.localizedDescription
        }
    }

    // MARK: - Expand a later day

    func ensureDayContent(_ day: LearningDay) async {
        guard !day.isGenerated, let path = activePath else { return }
        isWorking = true; errorMessage = nil
        defer { isWorking = false }
        let outline = decodeOutline(path.outlineJSON)
        let meta = outline?.days.first { $0.day == day.dayIndex }
        let prior = outline?.days.filter { $0.day < day.dayIndex }.map(\.subtopic) ?? []
        do {
            let res = try await client.expandLearningDay(
                topic: path.topic,
                dayIndex: day.dayIndex,
                subtopic: meta?.subtopic ?? path.topic,
                objective: meta?.objective ?? "",
                priorSubtopics: prior
            )
            fillDay(path: path, dayIndex: day.dayIndex, concept: res.concept, applyPrompt: res.applyPrompt, cards: res.cards)
            refresh()
        } catch {
            errorMessage = (error as? AIClient.ClientError)?.errorDescription ?? error.localizedDescription
        }
    }

    // MARK: - Completion

    func completeDay(_ dayIndex: Int) {
        guard let path = activePath else { return }
        store.markDayComplete(pathID: path.id, dayIndex: dayIndex)
        Telemetry.track(.learnDayCompleted(dayIndex: dayIndex))
        if dayIndex >= path.durationDays {
            store.markPathComplete(pathID: path.id)
            Telemetry.track(.learnPathCompleted(topic: path.topic))
        }
        refresh()
    }

    func abandon() {
        guard let path = activePath else { return }
        store.abandonPath(pathID: path.id)
        Telemetry.track(.learnPathAbandoned(atDay: currentDayIndex))
        refresh()
    }

    // MARK: - Helpers

    /// Insert the day's cards into the path's deck (shared SRS queue) and link them.
    private func fillDay(path: LearningPath, dayIndex: Int, concept: String, applyPrompt: String, cards: [FlashcardItem]) {
        var ids: [UUID] = []
        for card in cards.prefix(SM2Constants.maxCardsPerDeck) {
            let row = Flashcard(
                deckID: path.deckID,
                question: card.question,
                answer: card.answer,
                hint: card.hint,
                difficulty: card.difficulty,
                layerIndex: max(0, min(2, card.layer ?? 0))
            )
            modelContext.insert(row)
            ids.append(row.id)
        }
        try? modelContext.save()
        store.fillDay(pathID: path.id, dayIndex: dayIndex, concept: concept, applyPrompt: applyPrompt, cardIDs: ids)
    }

    private func decodeOutline(_ json: String?) -> LearningOutline? {
        guard let data = json?.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(LearningOutline.self, from: data)
    }
}
