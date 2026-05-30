# Phase 01 — Remove Focus + streak migration + telemetry

**Context:** `reports/scout-corrections.md` · `docs/v1-2-deep-learn-spec.md` §A

## Overview
- **Priority:** P1 (blocks everything; sets the clean slate)
- **Status:** pending
- Delete the Focus feature, repoint the displayed streak off `FocusSession`, swap telemetry events.
  Leave the Learn tab compiling via a placeholder Deep Learn section.

## Key insights
- `StreakEngine` (review-based) ALREADY exists and is ALREADY called on review completion
  (`ReviewSessionModel.swift:60`). Only the **displayed** stat still uses the Focus path. So streak
  "migration" is small: change what `StatsAggregator` returns + what Home/Profile read.
- Deleting `FocusSession.self` from the SwiftData schema is migration-safe: SwiftData drops the
  entity's table; no other model references `FocusSession` (only `StatsAggregator` queries it, removed
  here). Existing users lose historical focus rows — acceptable (Focus is being retired).

## Requirements
- Functional: app builds + runs with no Focus tab; bottom bar shows Home / Learn / Capture / Profile;
  Learn tab shows a placeholder "Deep Learn (coming soon)" section; streak number still renders from
  review activity; no dangling `FocusSession`/telemetry symbols.
- Non-functional: Swift 5.9-compat; each touched file < 200 lines.

## Architecture / data flow
- **Streak (after):** review completes → `ReviewSessionModel` → `StreakEngine.markReviewedToday()`
  (UserDefaults). Display: `StatsAggregator.compute()` → `stats.streakDays = StreakEngine(uid:).currentStreak()`
  → `TodaySnapshotCard` / `StatsGrid`. `FocusSession` no longer queried.

## Related code files
**Delete:**
- `AntiNoise/Features/Focus/FocusRootView.swift`
- `AntiNoise/Features/Focus/ViewModels/FocusSetupModel.swift`
- `AntiNoise/Features/Focus/Views/FocusSetupView.swift`
- `AntiNoise/Features/Focus/Views/FocusActiveView.swift`
- `AntiNoise/Features/Focus/Views/FocusResultView.swift`
- `AntiNoise/Core/Services/Focus/FocusSessionEngine.swift`
- `AntiNoise/Core/Models/FocusSession.swift`

**Modify:**
- `AntiNoise/Core/DesignSystem/Components/BottomTabBar.swift` — remove `focus` from `AppTab` enum
  (:4) + its `title`/`icon` cases (:11, :21).
- `AntiNoise/App/MainTabView.swift:45` — remove `case .focus: FocusRootView()`.
- `AntiNoise/App/AppRouter.swift` — remove any `.focus` reference + immersive-screen comment (:12)
  (keep `hideTabBar` mechanism — still useful for the lesson flow).
- `AntiNoise/Core/Persistence/PersistenceContainer.swift:11` — drop `FocusSession.self` from `Schema`.
- `AntiNoise/Core/Services/Stats/StatsAggregator.swift` — remove `focusStreakDays`+`totalFocusMinutes`
  fields & Focus queries (:9-10,:39-47,:63-74); add `streakDays`, set via
  `StreakEngine(uid: <uidProvider>).currentStreak(now:)`. (Pass uid into `compute` or `StatsAggregator`.)
- `AntiNoise/Features/Home/Views/TodaySnapshotCard.swift:17` — `stats.focusStreakDays` → `stats.streakDays`.
- `AntiNoise/Features/Profile/Views/StatsGrid.swift:10-11` — streak cell → `streakDays`; **drop**
  "Total focus" cell (default — see Q1).
- `AntiNoise/Core/Services/Telemetry/TelemetryEvent.swift` — remove `focusSessionCompleted` (:14,:35)
  and any `focus_session_started`; add `learnPathStarted`, `learnDayCompleted`, `learnPathCompleted`,
  `learnPathAbandoned` (enum case + `name` mapping).
- `AntiNoise/Features/Learn/LearnHubView.swift` (or `LearnHubModel`) — add placeholder Deep Learn
  section (static card "Deep Learn — coming soon", no nav). Replaced in phase 04.
- `AntiNoise/Core/Services/Account/AccountDeletionService.swift:146` — **build-breaker**: removes the
  `FetchDescriptor<FocusSession>` deletion block (the entity no longer exists). MUST fix in this phase
  or the build fails. (Add `LearningPath`/`LearningDay` deletion here in phase 02.)
- Verify `Core/Services/Account/UserDataExportPayload.swift` + `DataExportService.swift` — confirmed no
  `FocusSession` symbol refs (earlier grep matched generic "export" text only); no change needed for
  the build. Export *content* (focus sessions field) handled in phase 06 docs/JSON checklist.

## Implementation steps
1. Delete the 7 Focus files listed.
2. Remove `.focus` from `AppTab` + `BottomTabBar` title/icon; fix `MainTabView` switch; clean `AppRouter`.
3. Remove `FocusSession.self` from `PersistenceContainer` schema.
4. Rewrite `StatsAggregator`: drop Focus queries + `streakLength`; add `streakDays` from `StreakEngine`.
   Thread a `uid` in (Home/Profile VMs construct `StatsAggregator`; pass current uid).
5. Update `TodaySnapshotCard` + `StatsGrid` to read `streakDays`; remove "Total focus" cell.
6. Update `TelemetryEvent`: remove focus cases, add 4 learn cases + names.
7. Add placeholder Deep Learn section to Learn hub.
8. `xcodegen generate` then `xcodebuild ... build` — must succeed with zero references to deleted symbols.

## Todo
- [ ] Delete Focus feature + service + model files
- [ ] Remove `.focus` tab (enum, bar, MainTabView, AppRouter)
- [ ] Drop `FocusSession.self` from schema
- [ ] Repoint `StatsAggregator` streak to `StreakEngine`; remove focus minutes
- [ ] Update Home + Profile stat views
- [ ] Swap telemetry events
- [ ] Add Learn-tab placeholder section
- [ ] Fix `AccountDeletionService.swift:146` FocusSession deletion (build-breaker)
- [ ] Build green

## Success criteria
- `grep -rn "FocusSession\|FocusRootView\|focusStreakDays\|focusSessionCompleted" AntiNoise/` → no hits.
- App builds + runs; streak count matches review activity (test: complete a review → streak ≥1).
- Bottom bar = 4 tabs; Learn shows placeholder.

## Risk assessment
| Risk | L×I | Mitigation |
|------|-----|-----------|
| Streak resets to 0 for users (UserDefaults seeded only from review completions, not historical Focus) | M×M | Accepted — streak semantics changed by design; Focus streak was Pro-orthogonal anyway. Frame in ASC notes (phase 06). |
| SwiftData schema change crashes on launch for existing store | L×H | Removing an entity is additive-safe in SwiftData lightweight migration; verify on a device with existing store before ship (phase 07). |
| Hidden Focus reference outside grep (deeplink/router string) | L×M | Full `grep -rin "focus"` sweep at step 8; inspect non-obvious hits. |

## Rollback
Single-commit phase; `git revert` restores Focus + schema entry. No data migration to unwind (entity
removal only drops an unused table going forward).

## Next steps
Unblocks phase 02 (data model) and phase 04 (real Learn UI replaces placeholder).
