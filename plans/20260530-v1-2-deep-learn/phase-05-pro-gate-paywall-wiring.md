# Phase 05 — Pro-gate + paywall wiring

**Context:** `reports/scout-corrections.md` · `docs/v1-2-deep-learn-spec.md` §Pro-gating

## Overview
- **Priority:** P1
- **Status:** pending
- **Depends:** phase 04 (entry CTA exists).
- Deep Learn = **Pro-only, full**. Free users see the entry CTA → tap → paywall. No free trial course.

## Key insights
- Client gate: `SubscriptionStore.isPro` (`SubscriptionStore.swift:18`).
- Reuse `PaywallSheetView` (`Features/Paywall/PaywallSheetView.swift`) — same pattern as quota paywall.
- The **real** boundary is server-side (phase 03 rejects non-pro with 403). The client gate is UX so a
  free user sees the paywall instead of a 403 error.
- Card review (normal + layered v1.1) stays on the existing free quota — Deep Learn is the upper tier,
  it does NOT change free review limits.

## Requirements
- Functional: free user taps any Deep Learn entry → `PaywallSheetView` (trigger: deep-learn); does NOT
  call `/v1/learn/path`. Pro user → proceeds to opt-in/create. Telemetry `paywallShown(trigger:)`.
- Non-functional: Swift 5.9-compat.

## Architecture / data flow
```
tap Deep Learn CTA → DeepLearnModel.startRequested()
  → if !subscriptionStore.isPro → present PaywallSheetView(trigger: .deepLearn) → return (no network)
  → else → opt-in loading → AIClient.startLearningPath (phase 04)
```

## Related code files
**Modify:**
- `AntiNoise/Features/Learn/ViewModels/DeepLearnModel.swift` — inject `isProProvider: @MainActor () -> Bool`
  (pattern from `AISummarizer.swift:16`); gate `startRequested()` on it.
- `AntiNoise/Features/Learn/Views/DeepLearnSection.swift` — present paywall sheet on gated tap; the
  active-path card (for existing Pro paths) shows normally.
- `AntiNoise/Core/Services/Telemetry/PaywallTrigger` (enum in TelemetryEvent area) — add `.deepLearn`
  case if a trigger enum exists; else reuse closest existing trigger. Verify at impl.
- `AntiNoise/Features/Paywall/PaywallSheetView.swift` — only if it needs a Deep-Learn-specific headline
  (optional copy tweak; reuse as-is if generic).

## Implementation steps
1. Add `.deepLearn` to the paywall trigger enum (or reuse) + telemetry name.
2. Inject `isProProvider` into `DeepLearnModel`; branch in `startRequested()`.
3. Present `PaywallSheetView` from `DeepLearnSection` (and from the Mastered-deck CTA path) on gated tap.
4. Ensure no network call fires for free users.
5. Build + smoke: free account → CTA → paywall (no `/v1/learn/path` request); Pro account → proceeds.

## Todo
- [ ] `.deepLearn` paywall trigger + telemetry
- [ ] `isProProvider` gate in `DeepLearnModel`
- [ ] Paywall sheet presentation on gated entries
- [ ] No network for free users
- [ ] Smoke both tiers

## Success criteria
- Free user: every Deep Learn entry → paywall; zero `/v1/learn/*` requests (verify via proxy logs).
- Pro user: entry → creation flow.
- `paywall_shown` logged with deep-learn trigger.

## Risk assessment
| Risk | L×I | Mitigation |
|------|-----|-----------|
| Free user bypasses client gate (stale `isPro`) and hits backend | L×L | Server returns 403 (phase 03) → show paywall on 403 too. Defense in depth. |
| Active path created while Pro, user downgrades → can they finish? | M×M | **Decision needed** — default: keep access to an already-started path (cards already learned). Flag for user (see open Q). |

## Rollback
Gate is additive branching. Revert removes the gate (Deep Learn would be open — but backend 403 still
blocks free, so no security regression).

## Open questions
- Pro→free mid-path: keep access to the active path or lock it? Defaulting to **keep** (consistent
  with "abandoned path keeps cards"). Flag for user.

## Next steps
Unblocks phase 07 (gate tests).
