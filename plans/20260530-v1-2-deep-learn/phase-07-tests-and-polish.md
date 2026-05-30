# Phase 07 — Tests + polish

**Context:** `reports/scout-corrections.md` · all prior phases

## Overview
- **Priority:** P1 (ship gate)
- **Status:** pending
- **Depends:** phase 04 (UI), phase 05 (gate).
- Backend vitest + iOS unit/UI smoke + device migration check + final polish before ASC submit.

## Requirements
- Functional: all tests green; device build with an existing (v1.1) store launches without crash;
  end-to-end path lifecycle works on device.
- Non-functional: no failing tests ignored; Swift 5.9-compat.

## Test matrix
| Area | Level | What |
|------|-------|------|
| `/v1/learn/path` outline+Day1 parse | unit (vitest) | valid JSON → path+day1; malformed → 502; free → 403; quota peek 429; commit only on success |
| `/v1/learn/day` expand | unit (vitest) | valid → day content; card layer normalized 0-2; free→403 |
| `normalizeCards` helper | unit (vitest) | clamps layer, slices cap, defaults |
| `LearningPathStore` CRUD | unit (XCTest) | createPath → 1 path + 7 days; fetchActivePath; fillDay; markDayComplete advances currentDay; abandon keeps cards |
| Streak migration | unit (XCTest) | `StatsAggregator.streakDays` == `StreakEngine.currentStreak`; review completion increments streak |
| Schema migration | manual/device | launch with pre-existing v1.1 store → no crash; FocusSession entity removal clean |
| Pro-gate | UI smoke | free → paywall, no `/v1/learn/*`; pro → creates path |
| Lesson flow e2e | device | start → Day 1 concept+cards+apply → complete → Day 2 lazy-loads → … → Day 7 → badge |
| Resurfacing | unit/manual | prior-day due cards appear in later day review via SM-2 |

## Implementation steps
1. Backend: finalize `backend/test/learn-endpoints.test.ts`; `npm test` green.
2. iOS unit tests: `LearningPathStore`, streak migration (add to existing test target).
3. Device migration test: install v1.1 build, then this build over it → verify no crash + streak intact.
4. UI smoke: both tiers (free paywall, pro flow); full 7-day e2e on device.
5. Polish: loading/error copy, empty states (no active path), badge visuals, telemetry firing verified
   in Firebase DebugView.
6. Regression sweep: `grep -rin "focus" AntiNoise/ docs/` → only tagline remains.
7. `xcodegen generate` + release build; backend `wrangler deploy`.

## Todo
- [ ] Backend vitest green
- [ ] iOS `LearningPathStore` + streak tests green
- [ ] Device store-migration check (no crash)
- [ ] Pro-gate UI smoke (both tiers)
- [ ] Full 7-day e2e on device
- [ ] Resurfacing verified
- [ ] Telemetry verified in DebugView
- [ ] Focus regression grep clean
- [ ] Release build + backend deploy

## Success criteria
- All listed tests pass; no skipped/ignored failures.
- Device upgrade from v1.1 store → no crash, streak preserved.
- e2e path completes to badge; cards in shared SRS queue.
- Telemetry events fire; no Focus references remain.

## Risk assessment
| Risk | L×I | Mitigation |
|------|-----|-----------|
| SwiftData migration crash only on real device (not sim) | M×H | Explicit device upgrade test with real existing store (step 3) before submit. |
| Per-day review queue filter regresses normal deck review | M×M | Test both Deep Learn day review AND a normal deck review in same build. |
| Telemetry names typo'd (analytics silently wrong) | L×M | Verify in Firebase DebugView (step 5). |

## Rollback
Test/polish phase — no schema or API changes beyond fixes. If a blocker found, revert the offending
phase, not this one.

## Next steps
Ship: ASC submit with phase-06 what's-new. Post-ship: monitor completion rate; consider cron pre-gen +
14-day + adaptive difficulty (all deferred).
