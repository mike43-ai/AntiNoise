# Phase 04 — iOS Deep Learn UI + lesson flow

**Context:** `reports/scout-corrections.md` · `docs/v1-2-deep-learn-spec.md` §UX flow

## Overview
- **Priority:** P1
- **Status:** pending
- **Depends:** phase 02 (models), phase 03 (endpoints).
- Build the Learn-tab Deep Learn UI (replaces the phase-01 placeholder): entry CTA, opt-in loading,
  path screen, daily lesson flow, completion badge. **Open pacing — no countdown/lock UI.**

## Key insights
- Reuse `FlashcardReviewView` + `ReviewSessionModel`/`ReviewSessionEngine` for the card portion — Deep
  Learn cards are normal `Flashcard`s in the path's deck, so the existing due-queue review just works.
- `AppRouter.hideTabBar` (kept from phase 01) gives the lesson flow a full-screen surface.
- All 7 days available immediately. A day is "current" = first not-completed; days render as
  completed ✓ / current / not-yet-opened. No 🔒, no countdown.

## Requirements
- Functional:
  - Entry CTA from (a) a "Mastered" deck result and (b) a "Deep Learn" section in the Learn hub.
  - Opt-in → (Pro check in phase 05) → loading "⚡ Designing your 7-day path…" → calls
    `POST /v1/learn/path` → persists path + Day 1 (via `LearningPathStore`).
  - Path screen: progress "Day N/7", list of 7 days with state badges.
  - Tap current/any day: if `conceptText==nil` → call `POST /v1/learn/day` (loading) → fill → show
    lesson: concept → new layered cards (review) → apply prompt → resurface prior due cards (SM-2).
  - Day complete → `markDayComplete`, advance `currentDay`, telemetry `learnDayCompleted`.
  - Day 7 complete → `markPathComplete` → badge "Mastered [topic] in 7 days 🏆" + `learnPathCompleted`.
  - 1 active path at a time; starting new while active → prompt finish/abandon.
- Non-functional: Swift 5.9-compat; each view < 200 lines (split aggressively).

## Architecture / data flow
```
LearnHubView → DeepLearnSection (active path card OR "start" CTA)
  → start → DeepLearnOptInView (loading) → AIClient.startLearningPath() → LearningPathStore.createPath
  → LearningPathView (day list)
    → tap day → ensure day content (AIClient.expandLearningDay if nil) → LearningDayLessonView
       → concept → FlashcardReviewView(deckID, filtered to day cards + due resurfacing) → apply prompt
       → markDayComplete → back to LearningPathView
    → day 7 done → CourseCompletionView (badge)
```
Networking added to `AIClient`: `startLearningPath(...)`, `expandLearningDay(...)` mirroring
`refreshDailyInbox()` (`AIClient.swift:117`).

## Related code files
**Create (Features/Learn/Views/ + ViewModels/):**
- `DeepLearnSection.swift` — Learn-hub section: active-path summary card or start CTA.
- `DeepLearnOptInView.swift` — loading + error/retry during path creation.
- `LearningPathView.swift` — Day 1..7 list with state badges + progress header.
- `LearningDayLessonView.swift` — concept → cards → apply orchestration (uses `FlashcardReviewView`).
- `CourseCompletionView.swift` — "Mastered 🏆" badge (share deferred).
- `ViewModels/DeepLearnModel.swift` — owns path lifecycle, calls store + AIClient, exposes day state.
- `ViewModels/LearningDayModel.swift` — single-day content fetch + completion.

**Modify:**
- `AntiNoise/Features/Learn/LearnHubView.swift` (or `LearnHubModel`) — replace phase-01 placeholder
  with `DeepLearnSection`.
- `AntiNoise/Features/Learn/Views/ReviewSummaryView.swift` (the "Mastered" result for a deck) — add
  "Học sâu 7 ngày" CTA when a deck is mastered. (Confirm this is the right result screen at impl.)
- `AntiNoise/Core/Networking/AIClient.swift` — add `startLearningPath` + `expandLearningDay` +
  `Decodable` response DTOs (mirror `DailyRefreshResponse` at :231).
- `TelemetryEvent` calls — fire `learnPathStarted` (opt-in), `learnDayCompleted`, `learnPathCompleted`,
  `learnPathAbandoned`.

## Implementation steps
1. Add `AIClient.startLearningPath` / `expandLearningDay` + DTOs.
2. `DeepLearnModel`: createPath flow (call → persist via `LearningPathStore` → fill Day 1 cards).
3. `DeepLearnSection` in Learn hub (active card vs start CTA; enforce 1-active rule).
4. `LearningPathView` day list (state: completed/current/not-opened; no lock UI).
5. `LearningDayModel` + `LearningDayLessonView`: lazy day fetch, concept, cards via `FlashcardReviewView`,
   apply prompt, resurface due cards, mark complete.
6. `CourseCompletionView` badge on day 7.
7. Wire "Mastered deck" CTA in result screen.
8. Fire telemetry at each lifecycle point.
9. `xcodegen generate` + build + simulator smoke (start → day 1 → complete).

## Todo
- [ ] `AIClient` learn methods + DTOs
- [ ] `DeepLearnModel` + opt-in/create flow
- [ ] `DeepLearnSection` (replace placeholder)
- [ ] `LearningPathView` day list (no lock/countdown)
- [ ] `LearningDayModel` + `LearningDayLessonView` (concept→cards→apply→resurface)
- [ ] `CourseCompletionView` badge
- [ ] "Mastered deck" entry CTA
- [ ] Telemetry wiring
- [ ] Simulator end-to-end smoke

## Success criteria
- From Learn hub: start path → loading → Day 1 lesson renders concept + 3-5 layered cards + apply.
- Days 2-7 lazy-load on first open; reopening a completed day shows ✓, no regen.
- Day 7 completion shows badge; path status = completed; `learn_path_completed` logged.
- Only 1 active path; starting another requires finish/abandon.
- No countdown/lock UI anywhere.

## Risk assessment
| Risk | L×I | Mitigation |
|------|-----|-----------|
| `FlashcardReviewView` assumes whole-deck queue, not per-day subset | M×M | Filter the review queue to `LearningDay.cardIDs` ∪ due-resurfacing; verify `ReviewSessionEngine.dueCards` accepts a filter or add one. Check at impl. |
| Lazy day call fails mid-course → user stuck | M×M | Error+retry in `LearningDayModel`; day stays not-completed, re-openable. |
| Opt-in latency feels slow (2 Gemini calls) | M×L | Loading copy + spinner; consider optimistic path-screen reveal after outline, Day 1 fills async. |
| File bloat >200 lines | M×L | Split section/path/day/completion into separate files as listed. |

## Rollback
UI-only + 2 additive `AIClient` methods. Revert restores phase-01 placeholder; models/backend untouched.

## Next steps
Unblocks phase 05 (gate the entry CTA) and phase 07 (tests).
