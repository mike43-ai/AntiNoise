# Phase 10 — Home Dashboard + Profile Screens

## Context Links
- Parent: [plan.md](./plan.md)
- Deps: phase-07 (daily queue), phase-08 (decks/due cards), phase-09 (focus stats)
- Mockups: `Product UI/professional_profile_progress/screen.png`, `Product UI/kinetic_command/screen.png`, `Product UI/career_goals_anti_noise/screen.png`

## Overview
- Date: 2026-05-16
- Description: Home dashboard (today snapshot) + Profile (user, stats, goals, settings).
- Priority: P1
- Implementation status: pending
- Review status: pending
- Effort: 2d

## Key Insights
- Home is the first screen a returning user sees — it must show "what to do now" in one glance.
- Profile combines vanity stats (streak, focus minutes, cards reviewed) with action items (goals, settings, account).
- Kinetic command palette mockup → quick capture/search shortcut from Home.
- Account deletion LOCKED: Profile → Settings → Delete Account → 2-step flow: (1) export user data as JSON via share sheet, (2) confirm soft-delete. Soft-delete marks account `deletedAt = now`, signs user out, locks sign-in for 7 days. After 7 days hard-delete (Firestore + Firebase Auth + SwiftData wipe). Sign-in attempt within grace window → "Restore account?" prompt.

## Requirements
**Functional**
- Home shows: greeting, today's queue (top 3), due cards count, focus streak, single CTA "Start focus session".
- Quick command sheet (search captures, jump to deck) — from Home header icon (kinetic_command).
- Profile shows: avatar/initials, scope progress bars, goals list (edit), settings (notifications, theme, language, export, sign out, delete account).
- Settings → Account → Delete Account: 2-step flow
  1. Export data → JSON file via `UIActivityViewController` share sheet (user can save to Files/Drive/email).
  2. Confirm Delete → call `AccountDeletionService.softDelete(uid:)`:
     - Sets `deletedAt = now`, `hardDeleteAt = now + 7d` in Firestore `users/{uid}`.
     - Signs user out + clears local SwiftData.
     - Local UserDefaults flag prevents re-sign-up with same email for 7d (server-side check on next launch via Firestore lookup).
  3. Hard-delete trigger: on app launch, check `users/{uid}.deletedAt`. If `now > hardDeleteAt`, run hard-delete: Firestore docs purge, `Auth.auth().currentUser?.delete()`, RC `Purchases.shared.logOut`, SwiftData store reset. Out-of-band cleanup (Cloud Function on Firestore TTL) is v1.1.
- Data export schema (JSON top-level):
  ```jsonc
  {
    "exportedAt": "2026-05-16T12:00:00Z",
    "userId": "firebase-uid",
    "email": "user@example.com",
    "captures":   [{ "id": "...", "kind": "url|text|image", "rawText": "...", "sourceUrl": "...", "capturedAt": "..." }],
    "summaries":  [{ "id": "...", "captureId": "...", "simpleExplanation": "...", "analogy": "...", "knowledgeGaps": [...], "examples": [...], "deeperQuestion": "...", "classification": "personal|work|business", "generatedAt": "..." }],
    "decks":      [{ "id": "...", "summaryId": "...", "title": "...", "createdAt": "..." }],
    "flashcards": [{ "id": "...", "deckId": "...", "question": "...", "answer": "...", "easeFactor": 2.5, "intervalDays": 6, "repetitions": 2, "nextReviewAt": "...", "lastGrade": 5 }],
    "goals":      [{ "id": "...", "scope": "personal|work|business", "title": "...", "createdAt": "..." }]
  }
  ```
  Explicit whitelist — no API keys, no auth tokens, no internal flags.

**Non-functional**
- Home loads < 200ms cold (read SwiftData on-thread is fine for these counts).

## Architecture
```
Features/Home/
├── HomeRootView.swift
├── HomeViewModel.swift
├── Views/
│   ├── TodaySnapshotCard.swift
│   ├── DailyQueuePreview.swift
│   ├── DueCardsBadge.swift
│   ├── FocusStreakChip.swift
│   └── QuickCommandPalette.swift     (from kinetic_command)
Features/Profile/
├── ProfileRootView.swift
├── ProfileViewModel.swift
├── Views/
│   ├── ScopeProgressSection.swift    (from professional_profile_progress)
│   ├── GoalsListSection.swift
│   ├── StatsGrid.swift
│   ├── SettingsSection.swift
│   └── AccountActionsSection.swift
```

## Related Code Files (to create)
- `AntiNoise/Features/Home/HomeRootView.swift` (replaces phase-04 placeholder)
- `AntiNoise/Features/Home/HomeViewModel.swift`
- `AntiNoise/Features/Home/Views/TodaySnapshotCard.swift`
- `AntiNoise/Features/Home/Views/DailyQueuePreview.swift`
- `AntiNoise/Features/Home/Views/DueCardsBadge.swift`
- `AntiNoise/Features/Home/Views/FocusStreakChip.swift`
- `AntiNoise/Features/Home/Views/QuickCommandPalette.swift`
- `AntiNoise/Features/Profile/ProfileRootView.swift` (replaces phase-04 placeholder)
- `AntiNoise/Features/Profile/ProfileViewModel.swift`
- `AntiNoise/Features/Profile/Views/ScopeProgressSection.swift`
- `AntiNoise/Features/Profile/Views/GoalsListSection.swift`
- `AntiNoise/Features/Profile/Views/StatsGrid.swift`
- `AntiNoise/Features/Profile/Views/SettingsSection.swift`
- `AntiNoise/Features/Profile/Views/AccountActionsSection.swift`
- `AntiNoise/Features/Profile/Views/DeleteAccountFlowView.swift` (2-step: export → confirm)
- `AntiNoise/Core/Services/Stats/StatsAggregator.swift`
- `AntiNoise/Core/Services/Account/AccountDeletionService.swift` (soft-delete now, hard-delete after 7d)
- `AntiNoise/Core/Services/Account/DataExportService.swift` (assembles JSON per schema above)
- `AntiNoise/Core/Services/Account/UserDataExportPayload.swift` (Codable structs mirroring JSON schema)

## Implementation Steps
1. `StatsAggregator` computes from SwiftData: capturesToday, summariesToday, dueCards, focusStreakDays, totalFocusMinutes, scopeBreakdown (Personal/Work/Business counts + completion %).
2. `HomeViewModel.refresh()` runs on `.onAppear` + when daily queue invalidates.
3. `HomeRootView`: greeting (time-of-day aware), TodaySnapshotCard, DailyQueuePreview (top 3), DueCardsBadge, FocusStreakChip, "Start focus" CTA.
4. Quick command palette: presented as `.sheet`, fuzzy-search captures/decks via `String.localizedCaseInsensitiveContains`.
5. `ProfileViewModel` exposes user info from `AuthStore`, goals from phase-07 repo, stats from `StatsAggregator`.
6. `ProfileRootView` assembles sections. Settings rows: Notifications, Theme (system/light/dark), Language (VI/EN), Export data (JSON), Sign out, Delete account.
7. `DataExportService.exportAll(userId:)` → assembles `UserDataExportPayload` from SwiftData → encodes with `JSONEncoder(prettyPrinted, dateEncodingStrategy: .iso8601)` → writes to temp file `anti-noise-export-<userId>-<timestamp>.json` → returns URL.
8. Export from Settings: invokes `DataExportService` → `UIActivityViewController` share sheet.
9. Delete-account flow (`DeleteAccountFlowView`):
   - Step 1: full-screen warning + "Download your data" CTA → invokes `DataExportService` share sheet.
   - Step 2: explicit "I understand this will delete my account in 7 days" toggle + "Delete" button → calls `AccountDeletionService.softDelete()`.
   - On success → sign out + show 7-day grace info screen.
10. `AccountDeletionService.softDelete(uid:)`: write `deletedAt`/`hardDeleteAt` to Firestore, sign out, clear SwiftData.
11. On app launch (in `AntiNoiseApp.init` after Firebase configure): if `currentUser != nil`, fetch `users/{uid}.deletedAt`. If present + `now > hardDeleteAt` → `AccountDeletionService.hardDelete(uid:)`. If present + within grace → present "Restore account?" sheet on `RootView`.

## Todo
- [ ] StatsAggregator implemented
- [ ] HomeViewModel + view
- [ ] TodaySnapshotCard
- [ ] DailyQueuePreview wired to phase-07 engine
- [ ] DueCardsBadge wired to phase-08 scheduler
- [ ] FocusStreakChip wired to phase-09
- [ ] QuickCommandPalette search works
- [ ] ProfileViewModel + view
- [ ] ScopeProgressSection matches mockup
- [ ] GoalsListSection (add/edit/delete)
- [ ] SettingsSection rows
- [ ] DataExportService produces valid JSON matching schema
- [ ] Export → share sheet flow works
- [ ] DeleteAccountFlowView 2-step UX implemented
- [ ] AccountDeletionService.softDelete sets deletedAt + hardDeleteAt
- [ ] 7-day grace: sign-in during window → Restore prompt
- [ ] Hard-delete on launch when expired (Firestore + Auth + SwiftData)
- [ ] Sign out flow verified

## Success Criteria
- Home reflects latest captures within 1 frame of returning to tab.
- Profile streak matches actual completed focus sessions.
- Export produces valid JSON parseable by `JSONDecoder` and round-trips into `UserDataExportPayload`.
- Delete account → user signed out, sign-in blocked for 7 days with Restore prompt.
- After 7 days, next launch hard-deletes Firestore + Auth + SwiftData.

## Risk Assessment
- **R1**: Stats query slow at scale (10k captures). → Add SwiftData `#Predicate` filters + cache per-day aggregates.
- **R2**: Export accidentally includes API keys / tokens. → Whitelist export schema fields explicitly (see schema above).
- **R3**: Hard-delete tied to client launch → user never opens app again, data lingers. → Document as MVP limitation; v1.1 adds Firestore TTL + Cloud Function for server-driven hard-delete.
- **R4**: User signs in with Apple during grace window → may auto-create new account. → Check Firestore `users/{uid}.deletedAt` before continuing post-Apple-sign-in flow; if within grace, show Restore prompt.

## Security Considerations
- Delete account purges per phase-03 spec.
- Theme + notification toggles persisted in `UserDefaults(suiteName: appGroup)`.

## Next Steps
- Phase-11 paywall gates: high-volume export, advanced stats, AI quota.
