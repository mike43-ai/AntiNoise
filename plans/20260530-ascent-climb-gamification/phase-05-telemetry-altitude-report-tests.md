---
phase: 5
title: "Telemetry + altitude report + tests"
status: pending
priority: P2
effort: "2d"
dependencies: [3, 4]
---

# Phase 5: Telemetry + altitude report + tests

## Overview
Instrument the feature (so the economy can be tuned from real data), add the weekly altitude report,
cover the economy/season logic with unit tests, and verify migration on a real store.

## Requirements
- Functional: telemetry events fire at each lifecycle point; an altitude report summarizes the last
  7 days' elevation by source; unit tests cover earn rules, cap, streak multiplier, camp crossing,
  and season rollover.
- Non-functional: no skipped/failing tests; the tuning data needed (summit rate, median day-60
  elevation) is observable.

## Architecture
- Telemetry (add to `TelemetryEvent`): `expeditionStarted(biome:)`, `campReached(camp:)`,
  `summitReached(peak:)`, `expeditionExpired(elevation:)`, `elevationEarned(source:meters:)` (sampled
  or daily-aggregated to avoid event spam — prefer a daily `elevationDaySummary`). Names mapped in
  `TelemetryEvent.name`.
- `AltitudeReport`: derive from the last 7 `ElevationDay` rows (total + by-source breakdown) — pure
  function, shown as a card in the Ascent tab and used by tests.
- Tests target `AntiNoiseTests` (existing). Pure-logic where possible (economy/report/season math) +
  SwiftData store tests (mirroring `LearningPathStoreTests`).

## Related Code Files
- Modify: `AntiNoise/Core/Services/Telemetry/TelemetryEvent.swift` (add cases + names + params).
- Fire telemetry from `ExpeditionStore` / `ElevationService` at the lifecycle points.
- Create: `AntiNoise/Features/Ascent/Views/AltitudeReportCard.swift` + report derivation (in
  `AscentModel` or a small `AltitudeReport` helper).
- Create tests: `AntiNoiseTests/AscentEconomyTests.swift` (earn rules, cap, multiplier),
  `AntiNoiseTests/ExpeditionStoreTests.swift` (create/credit/camp-crossing/summit/expiry/season),
  `AntiNoiseTests/AltitudeReportTests.swift` (7-day breakdown).

## Implementation Steps
1. Add telemetry cases + names + params; fire from store/service.
2. `AltitudeReport` derivation + `AltitudeReportCard` in the tab.
3. Unit tests: economy (cap clamps, multiplier table, learning-only — no credit for non-due/hoarding),
   `ExpeditionStore` lifecycle, altitude report math.
4. `xcodegen generate` + run `AntiNoiseTests` green.
5. **Device migration check**: install over an existing store → no crash; existing data intact;
   Ascent starts cleanly.
6. Tuning note: record where to read summit-rate + median-day-60-elevation in Firebase to retune
   `AscentEconomy` post-launch.

## Success Criteria
- [ ] All new unit tests pass (no skips/fakes).
- [ ] Telemetry events visible in Firebase DebugView.
- [ ] Altitude report shows correct 7-day by-source totals.
- [ ] Device upgrade from a pre-Ascent store does not crash.

## Risk Assessment
- Telemetry event spam from per-credit events — aggregate to a daily summary event.
- Economy still unbalanced after launch — that's expected; constants are tunable, and the
  instrumentation here is what makes retuning possible. Do NOT treat the starter numbers as final.
