# Phase 12 — Polish + Launch Readiness

## Context Links
- Parent: [plan.md](./plan.md)
- Deps: phases 01–11 all complete
- Mockups: all (final pixel pass)

## Overview
- Date: 2026-05-16
- Description: Final polish, accessibility audit, performance pass, telemetry, App Store metadata, TestFlight beta, submission.
- Priority: P0 (gate to release)
- Implementation status: code-complete (a11y / perf / TestFlight / ASC submit deferred — external)
- Review status: pending
- Effort: 2d

## Key Insights
- Apple App Review rejection rate drops sharply when: account deletion works, privacy nutrition label is filled, demo account provided, in-app purchases properly described.
- App Store category LOCKED: Primary = Productivity, Secondary = Education.
- i18n LOCKED: Vietnamese + English at launch via `Localizable.xcstrings` (String Catalog, iOS 17+).
- Analytics LOCKED: Firebase Analytics only (no PostHog).
- Push notifications LOCKED: APNs entitlement + UNUserNotificationCenter. First permission prompt deferred to immediately AFTER onboarding (not at app launch). Two opt-ins surfaced: daily review reminder + streak nudge.
- Notification + Streak engine fits inside this phase (small surface — ~150 LOC). No new phase needed.

## Requirements
**Functional**
- Crash reporting (Firebase Crashlytics).
- Firebase Analytics event tracking (locked list below) — opt-out toggle in Profile settings.
- Push notifications: APNs entitlement, opt-in prompt post-onboarding, two reminder types (daily review + streak nudge).
- Streak engine: counts consecutive days with ≥1 completed review session (data from phase-08).
- Localization: VI + EN String Catalogs.
- App Store category: Primary Productivity, Secondary Education.
- Account deletion verified end-to-end (phase-10 flow).
- Privacy nutrition label data prepared.
- Empty states for every list.
- Error states for offline + API failure.

### Firebase Analytics event list (LOCKED)

| Event name              | Trigger                                                  | Params                                 |
|-------------------------|----------------------------------------------------------|----------------------------------------|
| `sign_up`               | First successful account creation                        | `method` (email / apple)               |
| `login`                 | Subsequent sign-in                                        | `method`                               |
| `capture_created`       | Capture row inserted                                      | `kind` (url/text/image), `source` (in_app / share_ext) |
| `summary_succeeded`     | `Summary` persisted                                       | `kind`, `latency_ms`                   |
| `summary_failed`        | After retry exhaustion                                    | `kind`, `error_code`                   |
| `deep_dive_started`     | User taps Deep dive on a Summary                          | —                                      |
| `deck_generated`        | CardGenerator persists Deck                               | `card_count`                           |
| `review_session_completed` | ReviewSummary view appears                             | `cards_reviewed`, `correct_count`      |
| `focus_session_completed`  | Focus timer finishes                                   | `duration_minutes`                     |
| `trial_started`         | RC trial activated                                        | —                                      |
| `trial_expired`         | TrialExpirySheet shown                                   | —                                      |
| `paywall_shown`         | Any paywall sheet shown                                  | `trigger` (trial_expiry / quota_capture / quota_ai / profile_upgrade) |
| `subscription_started`  | RC entitlement flips active (purchase or conversion)     | `product_id`                           |
| `quota_hit`             | UsageQuotaService blocks an action                       | `kind` (capture / ai_summary)          |
| `notification_opt_in`   | User grants APNs permission                               | `categories` (review,streak)           |
| `notification_tapped`   | Notification deep-link opens app                         | `category`                             |
| `account_export`        | Data export completes                                    | —                                      |
| `account_deleted`       | Soft-delete invoked                                      | —                                      |

**Non-functional**
- Cold launch < 2s on iPhone 12.
- Memory steady-state < 200 MB.
- Zero P0 bugs from internal beta.

## Architecture
No new components — hardening + glue.

## Related Code Files (to create / touch)
- `AntiNoise/Core/Services/Telemetry/Telemetry.swift` (event facade, Crashlytics + Firebase Analytics behind opt-in)
- `AntiNoise/Core/Services/Telemetry/TelemetryEvent.swift` (enum matching the locked event list)
- `AntiNoise/Core/Services/Telemetry/PrivacyConsentStore.swift`
- `AntiNoise/Core/Services/Notifications/NotificationService.swift` (UNUserNotificationCenter wrapper)
- `AntiNoise/Core/Services/Notifications/NotificationScheduler.swift` (schedules daily review + streak nudge)
- `AntiNoise/Core/Services/Notifications/StreakEngine.swift` (counts consecutive days w/ ≥1 completed review)
- `AntiNoise/Features/Onboarding/NotificationPermissionStep.swift` (post-onboarding prompt)
- `AntiNoise/Features/Profile/Views/PrivacyConsentRow.swift`
- `AntiNoise/Features/Profile/Views/NotificationSettingsSection.swift` (toggle review reminder + streak nudge)
- `AntiNoise/Resources/PrivacyInfo.xcprivacy` (required by Apple)
- `AntiNoise/Resources/Localizable.xcstrings` (VI + EN)
- `Tests/AntiNoiseTests/` smoke + unit tests for SM-2, classifier, quota, streak engine
- `Tests/AntiNoiseUITests/` 1 happy-path UI test (capture → summary → deep dive)
- `README.md` (update build + run + secrets)
- `LAUNCH_CHECKLIST.md` (in repo root)

## Implementation Steps
1. Add Firebase Crashlytics + Analytics SPM modules + dSYM upload script.
2. Build `Telemetry` facade: `track(event:params:)`, no-ops when consent off. Maps to `Analytics.logEvent(...)`.
3. Implement event call sites per LOCKED event list (in each owning phase's flow).
4. Add privacy consent step to onboarding + Profile toggle.
5. Fill `PrivacyInfo.xcprivacy` (tracking categories: User ID, App Info, Performance, Purchases).
6. **Notification + Streak engine**:
   - `NotificationService.requestAuthorization()` invoked from `NotificationPermissionStep` immediately after onboarding completes (NOT at first launch).
   - Two notification categories registered: `daily_review_reminder`, `streak_nudge`.
   - `NotificationScheduler.scheduleDailyReview(at:)`: user picks time (default 19:00 local), repeating `UNCalendarNotificationTrigger`.
   - `NotificationScheduler.scheduleStreakNudge()`: triggered when `StreakEngine` detects current streak ≥ 3 days AND no review done by 20:00 local time today → one-shot `UNTimeIntervalNotificationTrigger`.
   - `StreakEngine.currentStreak`: walks back from today counting consecutive days with `ReviewSession.completedAt` present. Exposed to Home (`FocusStreakChip`) + Profile.
   - Both toggles in `NotificationSettingsSection` (default: both ON if user granted APNs).
7. Empty state audit: every list (inbox, decks, due cards, focus history) has an `AppEmptyState`.
8. Error state audit: every async call has a visible error path.
9. Accessibility: VoiceOver labels on all interactive elements, Dynamic Type AX3 verified.
10. Performance pass: Instruments Time Profiler on Home / LearnHub / FlashcardReview.
11. Localization: extract strings → `Localizable.xcstrings` with `vi` + `en` translations. Cover UI strings, paywall copy, notification copy.
12. App Store assets: 6.7" + 6.1" screenshots from `Product UI/*/screen.png` mockups (re-render in app), app icon (1024x1024) from `anti_noise_minimal_wordmark`.
13. App Store metadata:
    - **Primary category**: Productivity
    - **Secondary category**: Education
    - Name, subtitle, description, keywords (VI + EN), privacy URL, support URL.
14. Demo account credentials provisioned for App Review.
15. Internal TestFlight build → 5+ testers → 1 week soak.
16. Submit to App Store Review.

## Todo
- [x] Crashlytics SPM linked + dSYM upload run script wired in project.pbxproj
- [x] Firebase Analytics SPM linked
- [x] Telemetry facade w/ opt-in (PrivacyConsentStore drives Analytics/Crashlytics collection toggles)
- [x] All LOCKED events instrumented at call sites
- [x] APNs entitlement enabled (aps-environment=development; bump to "production" for App Store builds)
- [x] NotificationService + NotificationScheduler
- [x] StreakEngine implemented (UserDefaults-backed Set<dayKey>)
- [x] NotificationPermissionStep post-onboarding (OnboardingFlowView step 2)
- [x] NotificationSettingsSection in Profile (daily review toggle + time + streak nudge toggle)
- [x] PrivacyInfo.xcprivacy filled (email/name/UserID/purchases/interaction/perf/crash/userContent)
- [x] Empty states audited — every list uses AppEmptyState
- [x] Error states audited — Auth/Capture/Profile flows surface errors via alert/text
- [ ] VoiceOver pass (deferred — needs simulator runtime)
- [ ] Dynamic Type pass (deferred — needs simulator runtime)
- [ ] Instruments perf pass (deferred — needs simulator runtime)
- [x] Localization VI + EN scaffolded (Localizable.xcstrings with paywall/onboarding/tab/profile keys; broader extraction via Xcode Localize action deferred)
- [ ] App icon + screenshots (external; needs ASC)
- [ ] App Store metadata (external; needs ASC)
- [ ] Demo account ready (external)
- [ ] TestFlight beta closed without P0 bugs (external)
- [ ] Submitted to review (external)

## Success Criteria
- App passes App Review on first or second submission.
- Crash-free sessions > 99% in beta.
- TestFlight feedback: ≥ 80% testers complete the capture → summary → flashcard flow without confusion.

## Risk Assessment
- **R1**: Rejection for missing account deletion. → Verified phase-03 + smoke-tested before submit.
- **R2**: Rejection for OpenAI key shipping in client. → Apple has not historically rejected for this; document risk; v1.1 server proxy.
- **R3**: Rejection for IAP description mismatch. → Pro tier description matches exactly what's gated in code.

## Security Considerations
- Final secrets audit: no API keys committed to git history (`git log -p | grep -E 'sk-|API_KEY'`).
- Privacy URL hosted (simple GitHub Pages page acceptable).

## Next Steps
- Post-launch: server proxy for OpenAI, FSRS migration, iOS Focus filter integration, widget support, watch app.
