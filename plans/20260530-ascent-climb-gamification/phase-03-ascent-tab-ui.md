---
phase: 3
title: "Ascent tab UI"
status: pending
priority: P1
effort: "3-4d"
dependencies: [1, 2]
---

# Phase 3: Ascent tab UI

## Overview
Replace the phase-1 placeholder with the real Ascent tab: a "today's climb" summary, a minimalist
topographic ascent visual showing the marker + camps, and distance-to-next-camp. Reads the active
expedition + today's elevation. The longest pole (visual polish).

## Requirements
- Functional: shows current elevation, % to summit, today's gained, next-camp distance, and the
  marker positioned along a contour visual. Empty state when no active expedition (CTA "Begin your
  ascent" or auto-start on first learn). Pull-to-refresh re-reads.
- Non-functional: on-brand minimalist (Space Grotesk numerals, Soft-Stone + Orange accent); each view
  < 200 lines (split: root, header, climb visual, camps strip).

## Architecture
```
AscentRootView (owns AscentModel: reads ExpeditionStore active expedition + today's ElevationDay)
  → TodaysClimbCard (elevation, % to summit, today's gain, pace vs target)
  → AscentVisualView (topographic contour path + animated marker at currentElevation/target)
  → CampsStrip (Base/I/II/III/Summit with reached/locked states)
```
- `AscentModel` (@Observable @MainActor): `expedition`, `todayElevation`, derived `progress`,
  `nextCamp`, `paceState`. Built from `ExpeditionStore` (no network).
- `AscentVisualView`: a `Shape`/`Canvas`-drawn contour profile with the marker interpolated along the
  path by `progress`; reuse `AppMotion` for the marker ease. Keep it a pure function of `progress` so
  it's testable + cheap. NO heavy 3D.

## Related Code Files
- Modify: `AntiNoise/Features/Ascent/AscentRootView.swift` (swap placeholder → real content + model).
- Create: `AntiNoise/Features/Ascent/ViewModels/AscentModel.swift`
- Create: `AntiNoise/Features/Ascent/Views/TodaysClimbCard.swift`
- Create: `AntiNoise/Features/Ascent/Views/AscentVisualView.swift`
- Create: `AntiNoise/Features/Ascent/Views/CampsStrip.swift`
- Reuse: `AppCard`, `AppColor` (AccentStrong added in v1.2 UI pass), `AppFont`, `AppMotion`,
  `AppLoadingIndicator`, `AppEmptyState`.

## Implementation Steps
1. `AscentModel` deriving progress/camps/pace from `ExpeditionStore`.
2. `AscentVisualView` contour + marker (progress-driven; start simple — polish iteratively).
3. `TodaysClimbCard` + `CampsStrip`.
4. Assemble in `AscentRootView`; empty state + refresh.
5. Build + simulator visual check (iPhone 15 + SE width).

## Success Criteria
- [ ] Tab shows real elevation/progress; marker sits at the right height for `currentElevation`.
- [ ] Camps render reached/locked correctly at 0/25/50/75/100%.
- [ ] Empty state shows before any learning; populates after a credited session.
- [ ] Looks on-brand on iPhone SE + 15 (no clipping).

## Risk Assessment
- Topographic visual eating time — timebox; ship a clean simple contour first, iterate later. The
  data correctness matters more than fancy terrain.
- Marker/animation jank — keep `AscentVisualView` a pure function of `progress`; animate value only.
