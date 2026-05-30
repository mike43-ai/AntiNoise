---
phase: 2
title: "Elevation economy + service + hooks"
status: pending
priority: P1
effort: "2d"
dependencies: [1]
---

# Phase 2: Elevation economy + service + hooks

## Overview
Implement the earn economy (tunable constants), an `ElevationService` that credits the active
expedition on real-learning events, and surgical hooks at the three existing event sites. **Learning
only** — no add-topic / card-flip / hoarding credit.

## Requirements
- Functional: completing a due-card review session credits elevation (per due card + session bonus,
  streak-multiplied, daily-capped); completing a Deep Learn day credits a chunk; a card's first-ever
  review credits the capture-loop bonus. Re-reviewing non-due cards credits 0.
- Non-functional: all numbers live in ONE `AscentEconomy` constants type (tunable); Swift 5.9-compat.

## Architecture
- `AscentEconomy` (enum of static constants — single source of truth):
  `metersPerDueCard = 10`, `sessionCompleteBonus = 20`, `deepLearnDay = 150`, `captureLoop = 30`,
  `dailyCap = 400`, streak multiplier table `[1:1.0, 3:1.1, 7:1.25, 14:1.5]`.
- `ElevationSource` enum: `reviews | deepLearn | capture`.
- `ElevationService` (@MainActor): `credit(meters:source:streakDays:now:)` → applies streak
  multiplier, clamps to remaining daily cap (reads/writes today's `ElevationDay` via `ExpeditionStore`),
  updates `Expedition.currentElevation`. No-op when there is no active expedition (auto-start one on
  first credit, or on tab first-open — decide in impl; prefer auto-start on first credit so a lapsed
  user resumes cleanly).
- **Hooks (surgical, at the same sites that already fire telemetry):**
  - `ReviewSessionModel.swift:~60` (session finished): credit `dueCardCount * metersPerDueCard +
    sessionCompleteBonus`, source `.reviews`, with `StreakEngine(uid).currentStreak()`. Count only
    cards that were due when the session started (track in the model).
  - First-ever review of a card (`card.repetitions == 0` before grading, inside `grade()`): credit
    `captureLoop`, source `.capture` (this is the trackable proxy for "capture→summarize→first review";
    simpler + abuse-proof vs threading capture provenance).
  - `DeepLearnModel.completeDay` (`:~98`): credit `deepLearnDay`, source `.deepLearn`.
- Pass an `ElevationService` (or a closure) into these models the same way `uidProvider` is injected —
  do NOT make `ElevationService` a global singleton; construct it from the view layer with the shared
  `ModelContainer` + uid, mirroring `DeepLearnModel` wiring.

## Related Code Files
- Create: `AntiNoise/Core/Services/Ascent/AscentEconomy.swift`,
  `AntiNoise/Core/Services/Ascent/ElevationService.swift`
- Modify: `AntiNoise/Features/Learn/ViewModels/ReviewSessionModel.swift` (credit on session end +
  first-review; thread in the service + due-count).
- Modify: `AntiNoise/Features/Learn/ViewModels/DeepLearnModel.swift` (credit on `completeDay`).
- Modify the views that construct those models (`FlashcardReviewView`, the Deep Learn flow) to inject
  the service.

## Implementation Steps
1. `AscentEconomy` constants + streak-multiplier helper.
2. `ElevationService.credit(...)` with cap + multiplier + auto-start-expedition; persists via
   `ExpeditionStore`.
3. Hook `ReviewSessionModel` (session-end credit using due-count snapshot; first-review credit).
4. Hook `DeepLearnModel.completeDay`.
5. Inject the service from the view layer (mirror `uidProvider` injection).
6. Build; manual check: a review session moves `currentElevation`.

## Success Criteria
- [ ] Completing a due review session increases `currentElevation` by the expected capped amount.
- [ ] Re-reviewing already-done (non-due) cards adds 0.
- [ ] Deep Learn day completion adds `deepLearnDay`.
- [ ] Daily total never exceeds `dailyCap` (post-multiplier).
- [ ] All elevation numbers grep to `AscentEconomy` only (no scattered literals).

## Risk Assessment
- Double-credit on retried sessions — credit once at the `.finished` transition, not per card grade
  (except the explicit first-review bonus). Guard with the existing finished-state check.
- Auto-start vs explicit-start expedition — auto-start on first credit avoids "earned but no season";
  document the choice.
