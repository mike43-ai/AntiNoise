# Phase 12 — Polish + Launch Readiness — Code Review

**Date:** 2026-05-17
**Scope:** Telemetry + Notifications + PrivacyInfo + xcstrings + onboarding step + project.pbxproj surgery
**Verdict:** **pass-with-notes**

Contract LOCKED items verified:
- 17 events present in `TelemetryEvent` enum, all instrumented at prescribed sites (single grep sweep). `signUp`, `login` (email + apple), `captureCreated`, `summarySucceeded`, `summaryFailed`, `deepDiveStarted`, `deckGenerated`, `reviewSessionCompleted`, `focusSessionCompleted`, `trialStarted`, `trialExpired`, `paywallShown` (×4 triggers), `subscriptionStarted`, `quotaHit` (capture+ai), `notificationOptIn`, `notificationTapped`, `accountExport`, `accountDeleted` — all wired.
- Opt-out (defaults ON) — `PrivacyConsentStore.init` returns `true` when key absent. ✓
- APNs entitlement set (`aps-environment=development`) — flip to `production` at archive time.
- Permission prompt is post-onboarding, not at launch (`OnboardingFlowView.Step` flow goes `profile → notifications`). ✓
- Streak counts consecutive days with ≥1 review — `StreakEngine.markReviewedToday` called inside `ReviewSessionModel.grade` on session-finish edge. ✓
- Daily review repeating + one-shot streak nudge at 20:00 — `NotificationScheduler` correct.
- `PrivacyInfo.xcprivacy` declares no tracking, no `NSPrivacyTrackingDomains`, no advertising IDs / contact-info beyond email+name.
- VI + EN coverage present in `Localizable.xcstrings`.

---

## Critical issues

**None.** No blockers for committing this phase.

---

## High-priority notes (defer, but flag in journal)

### N1 — `subscription_started` fires every customerInfo emission where `isPro` flips false→true

`SubscriptionStore.apply` is called from:
- `customerInfoStream` for-await loop (every push from RC backend)
- `signedIn(uid:)` after `Purchases.logIn`
- `signedOut()` after `logOut`
- `refreshCustomerInfo()` (Profile pull-to-refresh)
- `restorePurchases()` (Profile)

Question 4 (false→true twice in same session): yes, plausible.
Concrete path:
1. Cold start → `customerInfoStream` emits cached info → user is Pro → `previouslyPro=false → active=true` → fires.
2. Session expires offline → next emission says `active=false` → `previouslyPro=true → active=false` → no event.
3. Restore-purchases or backend re-confirms → `false → true` → **fires again**, same `productID`.

Severity: low for MVP analytics (will inflate `subscription_started` count when measuring activations vs. distinct customers — Firebase Analytics dedup on `user_id` mitigates partially), but worth tracking with a `lastFiredSubscriptionProductID` UserDefaults guard if this becomes a KPI.

### N2 — `trial_started` re-fire on app relaunch

Same shape as N1. On every cold launch the stream emits the cached customerInfo. Before `apply` is called for the first time, `previousTrialState == .notStarted`. So if user is mid-trial:
- Launch 1: `previousTrialState=.notStarted`, `trialState→.active` → fires `trial_started`. (intended)
- Launch 2 (next day): `previousTrialState=.notStarted` (reset), `trialState→.active` → **fires `trial_started` again**.

Because `previousTrialState` is read from `self.trialState` which is reset to `.notStarted` on every `SubscriptionStore` init. The store doesn't persist trialState across cold launches.

Fix later (post-MVP): persist a `hasEmittedTrialStarted` flag in UserDefaults keyed by RC original_transaction_id, or guard by `currentOffering` snapshot. For MVP launch, the inflation will be ~daily-actives × trial-active, which is small.

### N3 — Hardcoded strings in code don't all match `Localizable.xcstrings` keys

SwiftUI `Text("foo")` auto-localizes — but only if the literal exists in the catalog as a key. Spot checks:
- `Text("Profile")` (ProfileRootView L46) ↔ key present. ✓
- `Text("Sign out")` (button title in `SecondaryButton(title: "Sign out", …)`) — SecondaryButton presumably wraps `Text(title)`, so the literal must match. Key `"Sign out"` present. ✓
- `Text("Stats")` — **missing from xcstrings**.
- `Text("Goals")` — **missing**.
- `Text("Manage learning goals"`, `"Add OpenAI key"`, `"Manage OpenAI key"`, `"Export my data"`, `"Couldn't find this capture"`, `"Summarizing…"`, `"Summary failed"`, `"Time to review"` (notification content), `"Keep your streak"`, `"Focus session complete"`, etc. — all **missing**.
- DeleteAccountFlowView entire copy block — **missing**.
- NotificationPermissionStep bullet text — **missing** (only the headline + CTAs are localized).

Result: VI users will see English for a substantial portion of UX. The plan said "VI + EN localization" — the *infrastructure* is correct (catalog wired into Resources, sourceLanguage=en, vi variants where present), but coverage is partial.

Recommendation: defer (it's not a launch blocker if the marketed VI experience scopes to onboarding + paywall + privacy + tabs), but file a follow-up `phase-12.1-localization-coverage` issue. Worth calling out to PM before submitting to App Store as "fully localized to VI".

### N4 — Streak storage race (Q6)

`UserDefaults.set(Array(days), …)` does a synchronous read→mutate→write inside `markReviewedToday`. The Set-insert makes same-day calls idempotent (no duplicate keys). For *different* days written concurrently you'd lose data — but `markReviewedToday` only ever fires from MainActor-isolated `ReviewSessionModel.grade` (called from UI), so concurrency is bounded to one writer at a time.

**Verdict: acceptable for MVP.** No lock needed.

### N5 — Notification permission step shows even on re-onboarding (Q7)

`OnboardingFlowView` always transitions `profile → notifications`. There's no check for `notifications.authorizationStatus == .authorized || .denied`. Flows where it appears redundantly:

- Same device, fresh install, user previously granted → iOS will silently succeed on re-grant, user sees the bell screen + taps "Enable reminders" → no system prompt appears (already granted), just schedules silently. Mildly confusing but not broken.
- Same device, user previously *denied* → tapping "Enable reminders" calls `requestAuthorization` which returns `false` without prompting. User stays on the screen, eventually taps "Not now". Bad UX but recoverable from Profile.
- Sign-out then sign-in same UID → OnboardingStore.isCompleted resets per UID? Actually it's per-UID — re-signing the same account on the same device, `OnboardingStore.isCompleted(uid:)` returns true (it was persisted), so `RootView` skips the onboarding flow entirely. ✓
- Different UID on same device → re-runs onboarding, sees the bell screen → if APNs already authorized at OS level, "Enable reminders" succeeds silently. Fine.

**Verdict: acceptable.** Optional polish: skip the step (or change copy to "Already enabled — tap Continue") when `authorizationStatus != .notDetermined`. Defer.

---

## Medium-priority notes

### M1 — `Telemetry.consentProvider` race (Q1)

`nonisolated(unsafe) static var consentProvider` is read from non-MainActor contexts (e.g. `AISummarizer.process` is non-isolated) and written from `MainActor`-isolated `attach`. This is a classic Swift Concurrency unsafety dressed in `nonisolated(unsafe)` — compiler won't complain, but TSAN would flag.

Practical risk: zero. The closure swap happens once at bootstrap, before any non-MainActor `track` call. Subsequent reads see a stable value. Reads happen during normal product flow long after `attach`. Tearing of a function-pointer-sized atomic on ARM64 is benign (closure values are reference-counted; worst case a re-read sees the same closure twice).

**Verdict: acceptable.** If you want to satisfy TSAN cleanly, wrap in `OSAllocatedUnfairLock<…>` or convert to an actor. Defer to post-MVP.

### M2 — `Telemetry.attach` last-write-wins (Q2)

Confirmed: called exactly once in `AntiNoiseApp.bootstrap`. Comment-only suggestion: add a guard `precondition(currentProviderIsDefault)` to flag double-attach in DEBUG. Optional.

### M3 — `subscription_started` parameter handling for unsupported `@unknown` cases

`apply` switch on `entitlement.periodType` handles `.trial / .intro / .normal / .prepaid / @unknown` — `@unknown` falls to `.converted`. Correct; if RC adds `.lifetime` we still mark as converted (safest default) instead of losing the state.

### M4 — `NotificationScheduler` MainActor isolation (Q5)

`@MainActor struct` with all-static methods. The `@MainActor` is mostly meaningless on statics (it forces callers to be on MainActor when invoking, but the method body's effective isolation just means UserDefaults writes hop to main). UserDefaults is thread-safe anyway. The annotation is harmless and makes call-site discipline explicit. A plain `enum` with synchronous statics would be equivalent and slightly less ceremony.

**Verdict: not worth refactoring.** Code is correct.

### M5 — `NotificationScheduler` doesn't auto-schedule if user *re-enables* daily reminders later

In `NotificationSettingsSection.onChange(of: dailyEnabled)`, when `enabled=true` AND `authorizationStatus==.authorized` it calls `applyDailySchedule()`. If user toggles when `.notDetermined` or `.denied`, the toggle persists but nothing schedules — they're stuck unless they re-enter the section after granting permission. The `.task { await refreshAuthorizationStatus() }` does refresh on appear, but no re-schedule logic runs when authorization transitions externally.

Low impact (rare flow); defer.

### M6 — Notification content not localized

`NotificationScheduler` hardcodes English strings for title/body. `NSLocalizedString(_, comment:)` not used. VI users see English notification banners even with vi locale.

Recommendation: wrap in `String(localized: …)` so the xcstrings catalog can translate. Defer if N3 is deferred — same scope.

### M7 — `PrivacyInfo.xcprivacy` correctness (Q9)

Cross-check against actually-collected data:

| Declared type | Justified by |
|--|--|
| EmailAddress (linked, app-fn) | Firebase Auth email + email shown in Profile + Apple Sign-In email (relay or real) |
| Name (linked, app-fn) | Firebase Auth `displayName` |
| UserID (linked, app-fn + analytics) | Firebase Analytics `setUserID(uid)` from L43 of AntiNoiseApp |
| PurchaseHistory (linked, app-fn) | RevenueCat — does collect this. ✓ |
| ProductInteraction (linked, app-fn + analytics) | 17 telemetry events |
| PerformanceData (linked, app-fn + analytics) | Firebase Analytics + Crashlytics |
| CrashData (linked, app-fn) | Firebase Crashlytics |
| OtherUserContent (linked, app-fn) | Capture content sent to OpenAI |

Missing nothing material. Tracking flag false everywhere — correct given no advertising SDK and no 3rd-party trackers. Two API-access reasons declared (UserDefaults CA92.1 ≈ "access info from same app", FileTimestamp C617.1 ≈ "inside container"). Both valid.

**Verdict: ready for App Store submission.** Worth a final designer/legal eyeball before press-send.

### M8 — `CaptureSource.shareExt` declared but never emitted

`TelemetryEvent.swift` declares `case shareExt = "share_ext"`. Grep finds zero callers. The share extension queues to `SharedQueueStore` then the main app's `DrainQueueService` processes it without calling `Telemetry.track(.captureCreated(…))` for shared captures (DrainQueueService is out of phase 12 scope and not in the diff).

Result: share-ext captures don't show up in `capture_created` event count at all (not even as `in_app`). Funnel will under-count.

Recommendation: defer — DrainQueueService changes are out of scope for this phase. Add to phase-12.1 / launch journal: "wire `Telemetry.track(.captureCreated(kind:, source:.shareExt))` in DrainQueueService when first persisting a queued payload".

### M9 — Crashlytics build phase position (Q12)

Position: after `Embed Foundation Extensions`. Firebase recommends "after Copy Bundle Resources" (effectively last build phase). Current ordering = `Sources → Resources → Frameworks → Embed Foundation Extensions → Crashlytics`. Crashlytics is last. ✓

`alwaysOutOfDate = 1` is set. ✓
Input paths include `DWARF_DSYM_FOLDER_PATH` and `INFOPLIST_PATH`. ✓
Shell script: `"${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"` — this is the official SPM path. ✓

**Verdict: correct.** Note: there's no `${PROJECT_DIR}/$(GOOGLE_APP_ID)` arg passed. The Crashlytics SPM run script auto-detects from `GoogleService-Info.plist` so this is fine for the current bundling. If you later switch to a build setting–based GOOGLE_APP_ID, you'd add it as an arg.

### M10 — `project.pbxproj`: 14 new Swift files registered without PBXGroup membership

`FR0000000000000000000006..14` are declared as PBXFileReferences with `sourceTree = SOURCE_ROOT` and `path = "AntiNoise/Core/Services/Telemetry/..."` but they don't appear in any `PBXGroup.children` array (verified by grep against group definitions).

Build impact: zero — the files are listed in the AntiNoise target's Sources build phase via `BF…` IDs, so they compile and link.
Xcode IDE impact: they won't show up in the Project Navigator under their logical folder (Core/Services/Telemetry, etc.). They'll be invisible-but-compiled. Developer working in Xcode will be confused.

Recommendation (defer to post-MVP cleanup or do it now if you intend to keep working in Xcode): add each FR to the appropriate PBXGroup's `children` array. Or run `xcodeproj` ruby gem / a one-off script to normalize. Not a launch blocker.

The 4 stale AIUsageTracker refs are confirmed removed (`grep -c "AIUsageTracker" project.pbxproj` → 0).
All 14 BF / FR IDs are unique (`grep -c` → 3 occurrences each = 1 buildFile line + 1 fileRef line + 1 sources-phase line, as expected).
The `CFB123456789ABCDEFA00001` script-phase ID does not collide with any other ID in the project.

---

## Low-priority notes

### L1 — `PrivacyConsentStore` toggle calls Firebase setters even when Firebase isn't configured

`PrivacyConsentStore.didSet` and `.apply()` call `Analytics.setAnalyticsCollectionEnabled(…)` / `Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(…)` unconditionally. If `GoogleService-Info.plist` is missing (DEBUG sim without it), `FirebaseApp.app() == nil`, and these calls will crash or no-op depending on Firebase internals. `configureFirebaseIfPossible` guards `FirebaseApp.configure()` correctly, but the consent store doesn't check `FirebaseApp.app() != nil` before calling SDK methods.

Practical impact: zero in production (plist will exist). Dev annoyance for new contributors. Defer.

### L2 — `Telemetry.setUserID` doesn't clear Crashlytics user ID when uid is nil

```swift
static func setUserID(_ uid: String?) {
    guard consentProvider().analytics else { return }
    Analytics.setUserID(uid)
    if let uid {
        Crashlytics.crashlytics().setUserID(uid)
    }
}
```

When user signs out, `setUserID(nil)` clears Analytics but **not** Crashlytics — Crashlytics will still attribute crashes to the previous UID. Should also call `Crashlytics.crashlytics().setUserID("")` (empty string clears it).

Also note: this is gated on `analytics` consent, but Crashlytics user-ID gating should probably be on `crashlytics` consent. Currently if user disabled analytics but kept crashlytics, the UID never reaches Crashlytics on sign-in.

Defer — minor.

### L3 — `RootView.trialExpirySeen` and `NotificationScheduler` prefs use raw UserDefaults keys, not namespaced

Coexist fine, but consider a `UserDefaults` extension with typed accessors. Defer.

### L4 — `OnboardingFlowView.persist()` runs synchronously before `step = .notifications` transition — OK but no error path

If `OnboardingStore.setScopes` throws, user proceeds to notifications anyway with stale data. Phase-12 scope doesn't include changing OnboardingStore so leave alone.

---

## Explicitly good

- **De-dup logic for `trial_started` in same session is correct** (Q3): `if case .active = trialState, case .active = previousTrialState { /* no-op */ }`. The flicker case (refresh while trial still active) does NOT re-fire. The cross-session re-fire is N2 above, which is a different bug.
- **`subscription_started` reads productID from the actual entitlement**, so analytics distinguish between offerings (annual vs monthly). Clean.
- **`StreakEngine` uses `en_US_POSIX` for date formatter** — locale-stable. Won't silently change format under VI/AR locales.
- **`StreakEngine` uses `Calendar.current.startOfDay` cursor + day-by-day decrement**, so DST transitions and timezone changes are handled correctly (Calendar APIs respect the day-boundary semantics).
- **`AISummarizer.markFailed` increments `retryCount` only on terminal failure**, with a clarifying comment distinguishing it from `AIRetryEngine`'s in-attempt backoff. Excellent.
- **`SummaryDetailModel.cardCount` uses `fetchCount` instead of fetching the array** — avoids materializing flashcards just to count them. Right call.
- **`NotificationService` declared as `nonisolated` for `UNUserNotificationCenterDelegate` methods** — required by the protocol; the delegate methods touch only `Telemetry.track` which is itself nonisolated. Correct concurrency design.
- **`NotificationScheduler.scheduleStreakNudgeIfNeeded` returns early if `fireDate <= now`**, preventing a "fire immediately on app launch at 20:01" surprise.
- **`PrivacyInfo.xcprivacy` declares `NSPrivacyTracking=false` AND empty `NSPrivacyTrackingDomains`** — both required by Apple to claim "no tracking". Many apps miss the second key.
- **Onboarding flow gates the notification request behind a user-initiated tap on "Enable reminders"**, not on view-appear. iOS treats automatic prompts as a soft anti-pattern; this is the right pattern.
- **`@MainActor` annotation propagation is consistent** — `PrivacyConsentStore`, `NotificationService`, `NotificationScheduler` all isolated. `Telemetry` correctly stays nonisolated so non-UI code can call it.

---

## Unresolved questions

1. **N2 (cross-session `trial_started` re-fire)** — confirm with PM whether the dashboard is OK with this or needs a UserDefaults-backed de-dup before launch.
2. **N3 (localization coverage)** — confirm with PM whether shipping VI as "fully localized" requires the missing strings now, or whether onboarding + paywall + privacy + tabs is enough for v1.
3. **M8 (share-ext capture telemetry)** — confirm whether to land `Telemetry.track(.captureCreated(source:.shareExt))` inside DrainQueueService as part of this phase or push to a follow-up. Currently the `CaptureSource.shareExt` enum case is dead code.
4. **APNs environment** — entitlement says `development`. Confirm the archive build will flip to `production` via xcconfig override or the archive process for App Store distribution.
