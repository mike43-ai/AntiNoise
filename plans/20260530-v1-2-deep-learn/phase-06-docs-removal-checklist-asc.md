# Phase 06 — Docs removal checklist + ASC

**Context:** `reports/scout-corrections.md` · `docs/v1-2-deep-learn-spec.md` §Removal checklist

## Overview
- **Priority:** P1 (gates ship — legal/store accuracy)
- **Status:** pending
- **Depends:** phase 01 (Focus gone), phase 04 (Deep Learn exists, can be described).
- Purge Focus from legal/support/marketing docs + data-export content; add Deep Learn; write ASC notes.

## Key insights (verified line refs)
- `docs/legal/privacy-policy.md:30` — telemetry example lists "focus session started".
- `docs/legal/privacy-policy.md:85` — JSON export description includes "focus sessions".
- `docs/legal/support.md:11` — intro sells "built-in Focus timer".
- `docs/legal/support.md:60-66` — "Focus mode" FAQ + streak defined as "completed Focus session".
- `docs/legal/support.md:74,80,100` — feature lists + export description mention Focus.
- `docs/x-content-6-weeks.md:64,359,580` — marketing tweets sell "Focus timer + streak".
- Data export *payload*: `Core/Services/Account/UserDataExportPayload.swift` — remove the focus-sessions
  field from the export JSON; add `learningPaths`. (Confirm field name at impl.)

## Requirements
- Functional: no doc/marketing/legal/export text references Focus; streak redefined to "≥1 completed
  card review/day"; Deep Learn FAQ added; export JSON includes learning paths; ASC "what's new" framed
  as upgrade.
- Non-functional: factual accuracy (App Store rejection risk if features misstated).

## Related files
**Modify:**
- `docs/legal/privacy-policy.md` — :30 swap "focus session started" → a neutral example
  ("review session completed"); :85 export list "…flashcards, and focus sessions" → "…flashcards, and
  learning paths".
- `docs/legal/support.md` — :11 drop "built-in Focus timer" (→ Deep Learn or remove); :60-66 replace
  "Focus mode" FAQ with "Deep Learn" FAQ + **rewrite streak definition** to "consecutive days with ≥1
  completed card review"; :74,:80,:100 update feature/export lists.
- `docs/x-content-6-weeks.md` — :64,:359,:580 rewrite Focus-timer tweets → Deep Learn messaging.
- `AntiNoise/Core/Services/Account/UserDataExportPayload.swift` — remove focus-sessions field; add
  `learningPaths` (id, topic, currentDay, status, startedAt, day completions). Update
  `DataExportService.swift` accordingly.
- App Store Connect "What's New" (draft text in this phase; entered at submit): "Focus timer is
  replaced by **Deep Learn** — a 7-day mastery course that turns any deck into a guided deep-dive."

## Implementation steps
1. Edit privacy-policy lines 30, 85.
2. Rewrite support.md Focus → Deep Learn FAQ + streak definition + feature/export lists.
3. Rewrite the 3 x-content tweets.
4. Update `UserDataExportPayload` + `DataExportService`: drop focus, add learning paths; rebuild + verify
   export JSON shape.
5. Draft ASC what's-new + note Focus removal framing.
6. Final `grep -rin "focus" docs/ AntiNoise/` → only legitimate non-feature uses remain (e.g. "focus on
   what matters" tagline).

## Todo
- [ ] privacy-policy.md :30, :85
- [ ] support.md Focus→Deep Learn + streak redefinition (:11,:60-66,:74,:80,:100)
- [ ] x-content-6-weeks.md :64,:359,:580
- [ ] Data export payload: drop focus, add learning paths
- [ ] ASC what's-new draft
- [ ] Final focus-grep sweep clean

## Success criteria
- No Focus-feature references in legal/support/marketing/export.
- Streak definition in support.md matches code (`StreakEngine`).
- Export JSON includes learning paths; opens/validates.
- ASC what's-new ready.

## Risk assessment
| Risk | L×I | Mitigation |
|------|-----|-----------|
| App Store rejection for feature/privacy mismatch | M×H | Complete this phase BEFORE submit; legal text must match shipped app exactly. |
| "focus on what matters" tagline false-positive in grep | L×L | Manual review each hit; keep tagline. |
| Existing users' export loses focus history | L×L | Accepted — Focus retired; historical focus data not retained. |

## Rollback
Docs/text only + export payload. Revert restores prior text. No runtime impact (except export shape).

## Next steps
Gate for ship; run after phase 04 lands so Deep Learn copy is accurate. Phase 07 validates the build.
