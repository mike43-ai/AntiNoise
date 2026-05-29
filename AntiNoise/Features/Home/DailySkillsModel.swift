import Foundation
import Observation
import SwiftData

/// Identifiable wrapper for deck navigation from Home (raw UUID is already used
/// by the Home navigationDestination for capture → SummaryDetailView).
struct DeckRoute: Identifiable, Hashable {
    let id: UUID
}

@Observable
@MainActor
final class DailySkillsModel {
    enum LoadState: Equatable {
        case loading
        case idle
        case caughtUp
        case noProfile
        case error(String)
    }

    var items: [DailySkillItem] = []
    var state: LoadState = .idle
    var isStudying = false
    var quotaExceeded = false
    var toast: String?

    // Navigation outputs consumed by HomeRootView.
    var studyCaptureID: UUID? // Feynman → push SummaryDetailView
    var studyDeckRoute: DeckRoute? // Flashcards → push DeckDetailView

    private var hasLoaded = false

    private let modelContext: ModelContext
    private let aiClient: AIClient
    private let summarizerProvider: () -> SummarizerService
    private let cardGenerator: CardGenerator
    private let uidProvider: () -> String?
    private let isProProvider: () -> Bool

    init(
        modelContext: ModelContext,
        aiClient: AIClient,
        summarizerProvider: @escaping () -> SummarizerService,
        cardGenerator: CardGenerator,
        uidProvider: @escaping () -> String?,
        isProProvider: @escaping () -> Bool
    ) {
        self.modelContext = modelContext
        self.aiClient = aiClient
        self.summarizerProvider = summarizerProvider
        self.cardGenerator = cardGenerator
        self.uidProvider = uidProvider
        self.isProProvider = isProProvider
    }

    private var todayUTC: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    /// Called on Home appear. Shows cached items for today; if none cached yet
    /// (first run or a new day), fetches once. Guarded so it won't loop or burn
    /// quota on every appear.
    func loadOnAppear() async {
        loadCached()
        guard !hasLoaded else { return }
        hasLoaded = true
        if items.isEmpty {
            await refresh()
        }
    }

    func loadCached() {
        let today = todayUTC
        let descriptor = FetchDescriptor<DailySkillItem>(
            predicate: #Predicate { $0.date == today && !$0.skipped },
            sortBy: [SortDescriptor(\.title)]
        )
        items = (try? modelContext.fetch(descriptor)) ?? []
    }

    func refresh() async {
        state = .loading
        quotaExceeded = false
        let uid = uidProvider()
        let isPro = isProProvider()
        // Free tier: 1 daily-skills refresh per day. (Auto-refresh on first open
        // spends it; a manual re-tap past the cap → paywall.)
        guard UsageQuotaService.canConsume(.article, uid: uid, isPro: isPro) else {
            Telemetry.track(.quotaHit(kind: .article))
            quotaExceeded = true
            loadCached()
            state = .idle
            return
        }
        do {
            let resp = try await aiClient.refreshDailyInbox()
            switch resp.status {
            case "ok":
                _ = UsageQuotaService.consume(.article, uid: uid, isPro: isPro)
                replaceToday(with: resp.items)
                loadCached()
                state = items.isEmpty ? .caughtUp : .idle
            case "caught_up":
                items = []
                state = .caughtUp
            case "no_profile":
                items = []
                state = .noProfile
            default:
                loadCached()
                state = .idle
            }
        } catch let e as AIClient.ClientError {
            if case .rateLimited = e {
                quotaExceeded = true
                loadCached()
                state = .idle
            } else {
                state = .error(e.errorDescription ?? "Couldn't load today's skills.")
            }
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func skip(_ item: DailySkillItem) {
        item.skipped = true
        try? modelContext.save()
        loadCached()
    }

    /// "Study this" → text capture → summarize → generate layered deck. Both
    /// Feynman and Flashcards run the same pipeline; they differ only in which
    /// screen opens. Dedupes via studiedDeckID so a re-tap reopens the deck.
    enum StudyMode { case feynman, flashcards }

    func study(_ item: DailySkillItem, mode: StudyMode) async {
        guard !isStudying else { return }

        // Dedupe: already studied → just reopen.
        if let deckID = item.studiedDeckID {
            route(mode: mode, captureID: nil, deckID: deckID)
            return
        }

        let uid = uidProvider()
        let isPro = isProProvider()
        // A study = 1 "lesson" (3/month free). The summary step inside also
        // consumes .aiSummary; both are legitimate (summarize + generate deck).
        guard UsageQuotaService.canConsume(.lesson, uid: uid, isPro: isPro) else {
            Telemetry.track(.quotaHit(kind: .lesson))
            quotaExceeded = true
            return
        }

        isStudying = true
        defer { isStudying = false }

        let capture = Capture(kind: .text, rawText: item.studyText)
        do {
            try CaptureRepository(context: modelContext).insert(capture)
            Telemetry.track(.captureCreated(kind: .text, source: .inApp))

            // AISummarizer consumes the .aiSummary slot itself on success — do
            // NOT double-consume here (the pre-check above is just a UX gate).
            await summarizerProvider().process(captureID: capture.id)

            // Summarize may fail (network/AI) → no Summary row, capture .failed.
            // Bail with a clear message and remove the orphan so it doesn't show
            // up in Home "Up next".
            guard captureStatus(capture.id) == .summarized else {
                toast = "Couldn't summarize that right now — try again in a moment."
                modelContext.delete(capture)
                try? modelContext.save()
                return
            }

            let deckID = try await cardGenerator.generate(fromSummaryWithCaptureID: capture.id)
            _ = UsageQuotaService.consume(.lesson, uid: uid, isPro: isPro)
            item.studiedDeckID = deckID
            try? modelContext.save()
            route(mode: mode, captureID: capture.id, deckID: deckID)
        } catch {
            toast = error.localizedDescription
        }
    }

    private func captureStatus(_ id: UUID) -> CaptureStatus? {
        let ctx = ModelContext(modelContext.container)
        let descriptor = FetchDescriptor<Capture>(predicate: #Predicate { $0.id == id })
        return (try? ctx.fetch(descriptor))?.first?.status
    }

    private func route(mode: StudyMode, captureID: UUID?, deckID: UUID) {
        switch mode {
        case .feynman:
            if let captureID {
                studyCaptureID = captureID
            } else {
                studyDeckRoute = DeckRoute(id: deckID) // re-tap with no capture handle
            }
        case .flashcards:
            studyDeckRoute = DeckRoute(id: deckID)
        }
    }

    private func replaceToday(with dtos: [DailySkillDTO]) {
        let today = todayUTC
        // Remove any existing rows for today (a fresh refresh replaces them).
        let existing = (try? modelContext.fetch(
            FetchDescriptor<DailySkillItem>(predicate: #Predicate { $0.date == today })
        )) ?? []
        for row in existing { modelContext.delete(row) }
        for dto in dtos {
            modelContext.insert(DailySkillItem(
                skillId: dto.id,
                title: dto.title,
                keyword: dto.keyword,
                whyNow: dto.whyNow,
                coreConcept: dto.coreConcept,
                suggestedSearch: dto.suggestedSearch,
                pack: dto.pack,
                date: today
            ))
        }
        try? modelContext.save()
    }
}
