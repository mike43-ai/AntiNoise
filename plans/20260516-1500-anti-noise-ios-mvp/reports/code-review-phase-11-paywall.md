# Code Review — Phase 11 (RevenueCat paywall + subscription gating)

**Date:** 2026-05-17
**Reviewer:** code-reviewer
**Scope:** 11 files listed in review brief (subscription services, paywall sheets, wiring).
**Verdict:** **pass-with-notes** — one critical quota-accounting bug, two design ambiguities to confirm, rest minor.

---

## Critical issues (must fix before commit)

### C1. `AISummarizer.process()` consumes quota BEFORE `fetchAndClaim` — every retry of a failed capture burns another monthly slot

`AntiNoise/Core/Services/AI/AISummarizer.swift:40-50` — order is:

1. `UsageQuotaService.consume(.aiSummary, ...)`  ← increments counter
2. `fetchAndClaim(captureID:)`  ← short-circuits if not `.queued`

Concrete failure modes:

- **User retry path.** `SummaryDetailModel.retry()` sets `.failed → .queued`, then calls `summarizer.process(...)`. If the actual OpenAI call fails (network/decoding), the row goes back to `.failed`. User taps "Try again" → process() consumes another slot before even trying. A user who fails 3 times burns 4 of their 5 monthly summaries on a single capture.
- **Race between drains.** `DrainQueueService.ingest()` dispatches `process()` after inserting the row (`DrainQueueService.swift:62`). `PendingJobQueue.drain()` ALSO calls `process()` for every `.queued` row when reachability flips online (`PendingJobQueue.swift:25`). Both call paths consume a slot; only one wins `fetchAndClaim`. The loser burned a slot for free.
- **Already-processing row from another worker.** Same shape — slot consumed, work skipped.

**Fix:** swap the order. Claim first, consume second, then on `markFailed` for non-quota errors do not re-roll. Pseudocode:

```swift
let context = await MainActor.run { ModelContext(modelContainer) }
guard let capture = await fetchAndClaim(captureID: captureID, in: context) else { return }
let quotaOk = await MainActor.run { UsageQuotaService.consume(.aiSummary, uid: uid, isPro: isPro) }
guard quotaOk else {
    await markFailed(captureID: captureID, error: "Monthly AI summary limit reached…")
    return
}
// ... rest unchanged
```

Caveat: this means `.processing` status is set BEFORE the quota gate, so a quota-blocked row briefly flips to `.processing` then back to `.failed`. Acceptable — short window, status is durable through the failure.

Also consider: **on transient OpenAI failure, refund the slot.** Right now any network blip costs a monthly summary. That's a separate UX call though — flag and confirm with product before changing.

---

## Notes (good to fix, can defer)

### N1. Plan contradiction: does deck-gen consume `.aiSummary` quota?

Phase-11 plan is self-contradictory:

- Line 29: "Free tier: 3 captures/day + 5 AI summaries/month. **All other features (decks, focus, etc.) unlimited.**"
- Line 99 (acceptance checklist): "Paywall triggered on AI quota hit (SummaryDetailView **deck-gen** + AISummarizer fails capture)"

Implementation matches line 99 (`SummaryDetailModel.generateDeck` consumes `.aiSummary`). Means a Free user can spend their 5 monthly summaries on deck-gen and lock themselves out of new capture summaries. Not necessarily wrong but the plan needs reconciling. Decide:

- Keep current behavior → update plan line 29.
- Or: introduce a third quota bucket (`.deckGeneration`) → adds complexity, probably YAGNI for MVP.
- Or: deck-gen is Pro-only (current free quota gate is just "must be Pro") → simpler product story.

This is a **business decision** — surface to user, do not silently revise.

### N2. `AIUsageTracker` is dead code

`AntiNoise/Core/Services/AI/AIUsageTracker.swift` has zero callers anywhere in the project (`grep` confirms only its own definition). Its bucket-keying logic was superseded by `UsageQuotaService`. Delete the file to avoid future confusion about which counter is authoritative. The two services use different UserDefaults keys (`ai.usage.*` vs `quota.aiSummary.*`) so leaving it does no functional harm, but a future contributor will trip over it.

### N3. `trialExpirySeen` is a boolean, plan says "rate-limited to once per 24h"

`RootView.swift:10` uses `@AppStorage("trialExpirySeen") private var trialExpirySeen = false`. Plan called for 24h rate-limit via timestamp. Current behavior is **stricter** (once per account-session — tapping "Continue on Free" disables the sheet permanently until sign-out). Probably fine for MVP, but flag to product. If they want the 24h cadence, store `Date` and compare in the `.onChange(of: subscription.trialState)` guard.

### N4. `trialExpirySeen` resets on sign-out — re-prompts on re-sign-in

`RootView.swift:46-48` resets `trialExpirySeen = false` whenever auth leaves `.signedIn`. Means a user who:

1. Signs in
2. Sees trial expiry sheet, taps "Continue on Free"
3. Signs out (e.g. switch accounts, debugging)
4. Signs back into same account

…will see the trial-expiry sheet again. For genuinely-different accounts this is correct; for the same-account-re-sign-in case it's noise. Trade-off: keying `trialExpirySeen` per-UID (e.g. via `@AppStorage("trialExpirySeen.\(uid)")`) would solve both. Not blocking for MVP.

Pro users won't hit this because `subscription.trialState` won't be `.expired` for them — `apply()` sets `.converted` for active non-trial entitlements (`SubscriptionStore.swift:105-106`). Verified.

### N5. Quota burned before validation can fail

Two call sites consume quota then can still fail downstream:

- `CaptureFlowModel.save()` (line 83): consume → `buildCapture()` (can throw on image encoding) → `repo.insert()` (can throw). If either throws, slot is gone for no capture.
- `SummaryDetailModel.generateDeck()` (line 59): consume → `cardGenerator.generate(...)` (can throw). Same shape.

Low frequency in practice but irritating when it happens. Either move consume after the throwing work, OR add a refund path. Defer unless QA hits it.

### N6. Retrying a quota-blocked capture re-stamps `retryCount`

When `AISummarizer.process()` hits the quota path and `markFailed`s, it increments `capture.retryCount` (`AISummarizer.swift:143`). Plan-wise `retryCount` is meant for terminal AI failures, not quota refusals. Cosmetic — user pressing retry while quota-blocked just inflates this counter forever. Won't loop infinitely (each retry is user-driven) and the failure message is clear ("Monthly AI summary limit reached. Upgrade to Pro…") but the counter is misleading. Acceptable for MVP.

### N7. `CaptureFlowModel.toastMessage` set before quota gate would have fired correctly… but isn't set on quota-exceeded

Confirmed `save()` returns `.quotaExceeded` BEFORE setting toast, so no stale "Captured. Summarizing…" leaks. Good — call out to keep this behavior on future refactors.

---

## Verified non-issues (per your checklist)

- **Item 7 (concurrency).** `await MainActor.run { UsageQuotaService.consume(...) }` from non-isolated `AISummarizer.process()` is correct. `UsageQuotaService` is `@MainActor`, and `MainActor.run` from non-isolated context is the supported pattern. No deadlock.
- **Item 8 (env propagation).** All four sheet presentations (`RootView`, `CaptureFlowView`, `SummaryDetailView`, `ProfileRootView`) are descendants of the `RootView` that lives under `.environment(subscription)` in `AntiNoiseApp`. SwiftUI sheets inherit the env. Verified by reading the view hierarchy.
- **Item 9 (Pro bypass).** `UsageQuotaService.consume()` short-circuits via `canConsume` (returns true for `isPro`) then early-returns before the `defaults.set` increment. Pro users never touch the counter. Correct.
- **Item 10 (idempotency).** `onChange(of: auth.state)` only fires on actual `AuthState` transitions, not repeated identical states. `Purchases.shared.logIn(uid)` is idempotent for same-uid calls (RC returns existing customer info without re-aliasing). Safe.
- **Item 11 (style).** Matches existing patterns: `@Observable`, `@MainActor`, environment-based DI, sheet/state separation. No drift.

---

## Explicitly good — do NOT strip in a future simplify pass

- **`SubscriptionStore.apply()`** correctly distinguishes `.trial` / `.intro / .normal / .prepaid` periodTypes to drive `trialState`. The `.converted` path is what keeps trial-expiry sheet from re-firing for paying users. Subtle, correct, easy to break.
- **RC API key in Info.plist (`RCAppPublicKey`)** with empty-string fallback + DEBUG print. Keeps the binary clean, and the empty-key short-circuit means dev builds without the key won't crash — they just run with paywall disabled. Worth keeping.
- **`PaywallSheetView.onPurchaseCompleted` calls `refreshCustomerInfo()` then dismisses.** Refresh ensures `isPro` flips to true before downstream sheets re-render. Without this, a user who just upgraded could see the paywall close but `isPro` lag behind until `customerInfoStream` ticks.
- **`SummaryDetailView` uses `onDismiss: { model?.deckQuotaExceeded = false }`** on the quota sheet. Prevents stale-bool re-trigger if the user reopens the view. Defensive and correct.
- **`UsageQuotaService.bucketKey()` keys by UID + period.** Multi-user devices / sign-out/sign-in shuffles don't bleed quotas across accounts. The `_anon` fallback is documented and intentional.
- **`SubscriptionStore.signedOut()` swallows the "already-anonymous" throw with a comment.** Correct — RC throws when logging out an anon user, but we never want to surface that. Comment makes the intent durable.

---

## Unresolved questions

1. **Decide N1** (deck-gen on `.aiSummary` quota vs. unlimited). This is a business call; do not let an audit silently flip it.
2. **C1 fix shape** — claim-then-consume order is unambiguous, but: should transient OpenAI failures refund the slot? Affects how punitive the Free tier feels. Probably yes for decode/network 5xx, no for auth/4xx. Confirm before changing.
3. **N3 / N4** — confirm with product whether the once-per-session boolean is the desired behavior, or whether we want the per-24h-per-UID cadence the plan originally described.
