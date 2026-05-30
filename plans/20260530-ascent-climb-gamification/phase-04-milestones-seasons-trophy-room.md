---
phase: 4
title: "Milestones + seasons + trophy room"
status: pending
priority: P2
effort: "2-3d"
dependencies: [3]
---

# Phase 4: Milestones + seasons + trophy room

## Overview
Make the tab a destination: camp-milestone unlocks, a summit ceremony (confetti + haptic), automatic
season rollover to a new biome/peak, and a trophy room of summited peaks. Closes the day-61 cliff.

## Requirements
- Functional: reaching a camp shows a one-time unlock moment + records it; reaching the summit (or
  day 60 with summit elevation met) triggers a ceremony, awards a permanent peak badge, and starts a
  fresh expedition on the next biome; a trophy room lists all summited peaks. Missing the summit by
  day 60 expires the expedition and starts a new one (open question 4 default: clean reset, keep the
  badge as "reached Camp X").
- Non-functional: ceremony reuses `ConfettiView` + `Haptics` (summit only); Swift 5.9-compat.

## Architecture
- Camp-reached detection in `ExpeditionStore.addElevation` → returns any newly-crossed camp so the UI
  can present the unlock. Persist `reachedCamps` on `Expedition` (e.g. an `Int` high-water mark) to
  avoid re-firing.
- Summit/expiry handled on tab open + after each credit: if `currentElevation >= targetElevation`
  → `markSummited` + ceremony; if `now > startDate + 60d` and not summited → `markExpired` (record
  highest camp) + start next season.
- `SummitBadge` records: peakName, biome, summitedAt, finalElevation. Store as rows
  (`SummitedPeak` @Model) OR a JSON array on a profile key — prefer a light `@Model SummitedPeak`
  for the trophy list + Firestore mirror.
- Season start picks the next biome from `AscentBiomes` not equal to the last.

## Related Code Files
- Create: `AntiNoise/Core/Models/SummitedPeak.swift` (@Model: peakName, biome, summitedAt, elevation)
- Create: `AntiNoise/Features/Ascent/Views/SummitCeremonyView.swift` (reuse ConfettiView + Haptics)
- Create: `AntiNoise/Features/Ascent/Views/CampUnlockSheet.swift`
- Create: `AntiNoise/Features/Ascent/Views/TrophyRoomView.swift`
- Modify: `ExpeditionStore` — camp high-water tracking, summit/expiry transitions, season rollover.
- Modify: `AscentRootView`/`AscentModel` — present unlock/ceremony, link to trophy room.
- Modify: `PersistenceContainer` schema + `AccountDeletionService` — add `SummitedPeak`.

## Implementation Steps
1. Add `SummitedPeak` model + schema + deletion job.
2. `ExpeditionStore`: camp high-water, summit + expiry transitions, `startNextSeason`.
3. `CampUnlockSheet` (cosmetic reward MVP — open question 3 default: cosmetic).
4. `SummitCeremonyView` (confetti + success haptic + badge) → on dismiss start next season.
5. `TrophyRoomView` (grid of summited peaks) + entry point from Ascent header.
6. Build + simulate: force a summit (test elevation) → ceremony → new season → trophy shows the peak.

## Success Criteria
- [ ] Crossing a camp fires the unlock exactly once.
- [ ] Reaching summit elevation → ceremony, `SummitedPeak` recorded, new expedition (different biome).
- [ ] Day-60 without summit → expedition expires, new one starts, prior peak recorded at highest camp.
- [ ] Trophy room lists summited peaks; survives relaunch.

## Risk Assessment
- Re-firing camp/summit on every refresh — gate on persisted high-water + status; never derive
  one-time events purely from current elevation.
- Clock/timezone for day-60 — use local-day comparison consistent with `ElevationDay` date keys.
