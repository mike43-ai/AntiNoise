# Phase 09 — Focus Mode

## Context Links
- Parent: [plan.md](./plan.md)
- Deps: phase-04 (tab), phase-07 (daily queue), phase-08 (deck integration optional)
- Mockups: `Product UI/focus_session_setup_anti_noise/screen.png`

## Overview
- Date: 2026-05-16
- Description: Distraction-free session timer (pomodoro-style) optionally tied to a specific learning task (capture/deck/scope). Logs sessions for streaks + Profile stats.
- Priority: P2
- Implementation status: completed (2026-05-16)
- Review status: approved with fixes
- Effort: 1.5d

## Key Insights
- "Anti-noise" branding lives or dies on the Focus screen UX. Must feel calm.
- Integrate with iOS Focus filter API (`SetFocusFilterIntent`) post-MVP; for MVP, just in-app DND + screen-on prevention.
- Don't ship background audio just to keep timer alive — use `ProcessInfo.processInfo.beginActivity` + local notification for completion.

## Requirements
**Functional**
- Setup screen: pick duration (15/25/45/custom), pick optional target (capture, deck, or scope).
- Active screen: large minimal timer, target name, pause/end controls.
- Completion: confetti-free completion screen with options "Review cards (if deck linked)" / "Done".
- Session log persisted to `FocusSession` for stats.

**Non-functional**
- Timer accurate ± 1s over 60 min on background return.
- Screen stays on during session (`UIApplication.shared.isIdleTimerDisabled = true`).

## Architecture
```mermaid
flowchart LR
  Setup[FocusSetupView] --> Engine[FocusSessionEngine]
  Engine --> ActiveView[FocusActiveView]
  Engine --> Persistence[(FocusSession)]
  Engine --on complete--> Result[FocusResultView]
  Result -->|if deck linked| PhaseEightReview[FlashcardReviewView]
```

## Related Code Files (to create)
- `AntiNoise/Core/Models/FocusSession.swift` (`@Model`, fields: id, startedAt, endedAt?, plannedDuration, targetKind, targetId?, completed)
- `AntiNoise/Core/Services/Focus/FocusSessionEngine.swift` (`@Observable`)
- `AntiNoise/Features/Focus/Views/FocusRootView.swift` (replaces phase-04 placeholder)
- `AntiNoise/Features/Focus/Views/FocusSetupView.swift` (matches `focus_session_setup_anti_noise`)
- `AntiNoise/Features/Focus/Views/FocusActiveView.swift`
- `AntiNoise/Features/Focus/Views/FocusResultView.swift`
- `AntiNoise/Features/Focus/ViewModels/FocusSetupModel.swift`

## Implementation Steps
1. Define `FocusSession` model + `FocusTargetKind` enum (none, capture, deck, scope).
2. `FocusSessionEngine`:
   - `start(duration:, target:)` → records `startedAt`, schedules `Timer.publish` to update `remaining`.
   - `pause() / resume() / abort() / complete()`.
   - On `applicationDidEnterBackground`: store `startedAt` and compute remaining from wall clock on resume — never trust in-process timer alone.
   - Schedule local notification at completion time (request perm on first focus run).
3. `FocusSetupView`: duration chips, target picker (linking to capture/deck list).
4. `FocusActiveView`: huge mono digit timer, target chip, "End early" button.
5. `FocusResultView`: minutes focused + "Review now" CTA if target was a deck.
6. Persist `FocusSession` with `completed = (endedAt - startedAt >= planned * 0.9)`.
7. Streak logic: consecutive days with ≥1 completed session — surface in Profile (phase-10).

## Todo
- [ ] FocusSession model
- [ ] FocusSessionEngine with background-safe timing
- [ ] Local notification on completion
- [ ] FocusSetupView matches mockup
- [ ] FocusActiveView calm UI
- [ ] FocusResultView with optional review CTA
- [ ] Streak computation
- [ ] Screen-on toggle scoped to active session only

## Success Criteria
- Lock device for 25 min then unlock → timer reads ~0:00 within 1s tolerance.
- Completion notification fires even if app backgrounded throughout.
- Aborted session NOT counted toward streak.

## Risk Assessment
- **R1**: User denies notification permission → silent completion. → Fall back to in-app banner; document in onboarding.
- **R2**: `isIdleTimerDisabled` left on after abort → battery drain. → Always reset in `.onDisappear` of `FocusActiveView`.

## Security Considerations
- N/A (no data sent off-device).

## Next Steps
- Phase-10 Profile shows streak + total focus minutes.
- Future: iOS Focus filter integration (post-MVP).
