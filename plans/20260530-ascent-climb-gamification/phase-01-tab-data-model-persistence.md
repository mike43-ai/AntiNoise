---
phase: 1
title: "Tab + data model + persistence"
status: pending
priority: P1
effort: "1-2d"
dependencies: []
---

# Phase 1: Tab + data model + persistence

## Overview
Add the `.ascent` tab (placeholder UI), the `Expedition` + `ElevationDay` SwiftData models, an
`ExpeditionStore` (CRUD + season lifecycle), and a best-effort Firestore mirror. Foundation only —
the real tab UI lands in phase 3.

## Requirements
- Functional: a 5th tab appears (Home / Learn / Capture / Ascent / Profile) showing a placeholder;
  an active `Expedition` can be created with 60-day defaults + queried; rows survive relaunch.
- Non-functional: Swift 5.9-compat; models < 200 lines; additive SwiftData migration (no crash on an
  existing store).

## Architecture
- `Expedition` (@Model): id, peakName, biome, startDate, durationDays=60, targetElevation,
  currentElevation=0, status="active". `ElevationDay` (@Model): id, expeditionID, date (yyyy-MM-dd
  local), elevation, fromReviews, fromDeepLearn, fromCapture — one row/day (drives anti-abuse cap +
  altitude report). Literal defaults → additive-migration-safe.
- `ExpeditionStore` (@MainActor): `activeExpedition()`, `startExpedition(now:)` (picks next biome +
  peak name), `addElevation(_:source:now:)` (updates today's `ElevationDay` + expedition total,
  honoring the daily cap), `markSummited` / `markExpired`. Season rollover logic lives here.
- `ExpeditionSyncService`: mirror `Expedition` metadata to Firestore `expeditions/{uid}/seasons/{id}`
  (model on `LearningPathSyncService`).
- Biome/peak naming: a small static `AscentBiomes` table (name + biome id pool), cycled per season.

## Related Code Files
- Create: `AntiNoise/Core/Models/Expedition.swift`, `AntiNoise/Core/Models/ElevationDay.swift`
- Create: `AntiNoise/Core/Services/Ascent/ExpeditionStore.swift`
- Create: `AntiNoise/Core/Services/Ascent/AscentBiomes.swift`
- Create: `AntiNoise/Core/Services/Sync/ExpeditionSyncService.swift`
- Create: `AntiNoise/Features/Ascent/AscentRootView.swift` (placeholder "Ascent — coming soon")
- Modify: `AntiNoise/Core/DesignSystem/Components/BottomTabBar.swift` — add `.ascent` to `AppTab`
  (:4) + title/systemImage cases (icon e.g. `mountain.2`).
- Modify: `AntiNoise/App/MainTabView.swift` — add `case .ascent: AscentRootView()`.
- Modify: `AntiNoise/Core/Persistence/PersistenceContainer.swift` — add `Expedition.self`,
  `ElevationDay.self` to the `Schema`.
- Modify: `AntiNoise/Core/Services/Account/AccountDeletionService.swift` — add deletion jobs for both.

## Implementation Steps
1. Add `Expedition` + `ElevationDay` models with literal defaults.
2. Register both in `PersistenceContainer` schema; add deletion jobs.
3. Write `AscentBiomes` (≥5 biome/peak entries) + `ExpeditionStore` (CRUD, cap-aware `addElevation`,
   season rollover scaffolding — full rollover UX in phase 4).
4. Write `ExpeditionSyncService` (Firestore mirror).
5. Add `.ascent` to `AppTab` (enum + title + icon) and `MainTabView`; create `AscentRootView`
   placeholder.
6. `xcodegen generate` + build.

## Success Criteria
- [ ] Bottom bar shows 5 tabs incl. Ascent (placeholder renders).
- [ ] Creating an expedition persists 1 `Expedition`; reopening app keeps it; `activeExpedition()`
      returns it.
- [ ] Launch with a pre-existing store does not crash.
- [ ] `grep` shows no hardcoded elevation numbers yet (economy lives in phase 2).

## Risk Assessment
- SwiftData migration on real device — mitigate with literal defaults (additive); verify in phase 5.
- 5-tab crowding on small devices — Ascent icon/label must fit; check on iPhone SE width.
