# Scout corrections — verified against live code (2026-05-30)

These override `docs/v1-2-deep-learn-spec.md` where they conflict.

## Verified findings

1. **No lock/unlock/countdown infra exists.** `grep -rn "unlocksAt\|isLocked\|countdown" AntiNoise/` →
   zero hits. The spec's "reuse v1.1 lock/countdown/unlock + daily push" (spec §B2, §UX-5) is INVALID.
   → Pacing is OPEN. `LearningDay` has **no `unlocksAt`**. No countdown UI, no unlock-gating, no
   "Day N unlocked" push.

2. **No cron in backend.** `grep -rn "cron\|scheduled" backend/src backend/wrangler.toml` → zero hits.
   Day content is generated on-open via `POST /v1/learn/day`. Cron pre-gen DEFERRED (future optimization).

3. **Notification infra already exists, independent of Focus** —
   `AntiNoise/Core/Services/Notifications/{NotificationService,NotificationScheduler,StreakEngine}.swift`.
   Do NOT plan to "extract notification logic from FocusSessionEngine". Reuse the existing service.
   Daily "continue your path" reminder is OPTIONAL/DEFERRED (no gate requires it).

4. **Streak is already partly migrated.**
   - `StreakEngine.swift` computes streak from "≥1 review session/day" via UserDefaults.
   - It is ALREADY called on review completion: `ReviewSessionModel.swift:60`
     `StreakEngine(uid: uidProvider()).markReviewedToday()`.
   - `NotificationScheduler.swift:76-90` already uses `StreakEngine.currentStreak`.
   - BUT the **displayed** streak still reads the old Focus path:
     `StatsAggregator.swift:47` computes `focusStreakDays` from completed `FocusSession`s; rendered at
     `Home/Views/TodaySnapshotCard.swift:17` and `Profile/Views/StatsGrid.swift:10`.
   → Migration = repoint the displayed stat to `StreakEngine.currentStreak()`, drop the
     `FocusSession`-based `streakLength` + `totalFocusMinutes`. (Deep-Learn reviews already feed
     `StreakEngine` because they go through `ReviewSessionModel`.)

## Reuse map (verified file:line)

| Need | Reuse | Location |
|------|-------|----------|
| Card model w/ SM-2 + layer | `Flashcard` (`layerIndex`, `easeFactor`, `intervalDays`, `repetitions`, `nextReviewAt`) | `Core/Models/Flashcard.swift:6-22` |
| Deck (cards group by `deckID`) | `Deck` (`isLayered`) | `Core/Models/Deck.swift:7-14` |
| SRS scheduling | `SpacedRepetitionScheduler` | `Core/Services/Learning/SpacedRepetitionScheduler.swift` |
| Review run loop | `ReviewSessionEngine` + `ReviewSessionModel` | `Core/Services/Learning/ReviewSessionEngine.swift`, `Features/Learn/ViewModels/ReviewSessionModel.swift` |
| Review UI | `FlashcardReviewView` | `Features/Learn/Views/FlashcardReviewView.swift` |
| Backend AI call | `callAI` + system prompts | `backend/src/openrouter-client.ts:44,110,134,155` |
| Quota gate (peek/commit) | `peekUsage`/`commitUsage` | `backend/src/rate-limiter.ts:42,66` |
| Auth + tier middleware | `c.get('user')`, `c.get('tier')` | `backend/src/index.ts:170-171` |
| Firestore write pattern | `writeDailyInbox`, `getUserProfile` | `backend/src/firestore-client.ts:65,87` |
| iOS → backend client | `AIClient.performRequest`/`send` | `Core/Networking/AIClient.swift:92,131` |
| Pro check | `SubscriptionStore.isPro` | `Core/Services/Subscription/SubscriptionStore.swift:18` |
| Paywall | `PaywallSheetView` | `Features/Paywall/PaywallSheetView.swift` |

## Things to delete (verified present)
- `Features/Focus/{FocusRootView,ViewModels/FocusSetupModel,Views/FocusSetupView,Views/FocusActiveView,Views/FocusResultView}.swift`
- `Core/Services/Focus/FocusSessionEngine.swift`
- `Core/Models/FocusSession.swift`
- `BottomTabBar.swift:4,11,21` `.focus` case
- `MainTabView.swift:45` `case .focus: FocusRootView()`
- `AppRouter.swift` `AppTab` enum (verify `.focus` member) + comment at :12
- `TelemetryEvent.swift:14,35` `focusSessionCompleted` (+ any `focus_session_started` — grep found only `focusSessionCompleted` enum case; confirm at implementation time)
- `PersistenceContainer.swift:11` `FocusSession.self` from schema
- `StatsAggregator.swift:9-10,39-47,63-74` Focus-session streak + minutes
- `Profile/Views/StatsGrid.swift:11` "Total focus" cell

## Unresolved questions (for user)
1. `StatsGrid` "Total focus" stat is removed with Focus — replace with what? (suggest: "Cards mastered"
   or "Paths completed", or just drop the cell). Defaulting to **drop the cell** unless told otherwise.
2. `DashboardStats.focusStreakDays` field name — rename to `streakDays`? (cosmetic, touches 3 call
   sites). Defaulting to **rename** for clarity.
3. Backend path prefix — spec writes `/learn/path`; existing routes are `/v1/...`. Defaulting to
   `/v1/learn/path` and `/v1/learn/day` (consistent with `/v1/daily/refresh`).
