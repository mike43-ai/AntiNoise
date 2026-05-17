# Launch Checklist — Anti Noise iOS MVP

Items required before App Store submission. Each item is external to the codebase (needs Xcode UI, App Store Connect, or live keys).

## Secrets + Credentials

- [ ] **Firebase `GoogleService-Info.plist`** dropped into `AntiNoise/Resources/` (currently only an `.example.plist` placeholder). App boots without it but auth + analytics are disabled.
- [ ] **RevenueCat public API key** set in `Info.plist` under key `RCAppPublicKey`. Without it, `SubscriptionStore.bootstrap` short-circuits (logged in DEBUG).
- [ ] **`DEVELOPMENT_TEAM` set** in `AntiNoise.xcodeproj` (or via `Config.local.xcconfig`). Required for keychain-access-groups + share extension keychain reads.

## Entitlements + Capabilities

- [ ] **`aps-environment`** in `AntiNoise/Resources/AntiNoise.entitlements` is `development`. **Flip to `production` for App Store archives** (or wire a Debug/Release split via xcconfig). Without this flip, APNs deliveries to production builds will fail silently.
- [ ] **APNs key uploaded** to Firebase Console → Cloud Messaging (only if remote push is added post-MVP; local notifications work without this).
- [ ] **Sign In with Apple** capability enabled in Apple Developer portal (already in entitlements).

## App Store Connect

- [ ] **Bundle ID** `com.antinoise.shared` (or whichever production ID) registered.
- [ ] **Pro monthly + annual SKUs** created with **7-day intro offer attached to monthly**. SKU IDs must match what `Offering` returns from RevenueCat.
- [ ] **App Store metadata**:
  - Primary category: **Productivity**
  - Secondary category: **Education**
  - Name, subtitle, description, keywords (VI + EN)
  - Support URL, Privacy URL
- [ ] **Privacy nutrition label** filled to match `AntiNoise/Resources/PrivacyInfo.xcprivacy` (data types: User ID, Email, Name, Purchase History, Product Interaction, Performance Data, Crash Data, User Content). All linked to identity, none used for tracking.
- [ ] **Demo account** provisioned with sample captures, summaries, and Pro entitlement so App Review can exercise paywall flows.
- [ ] **6.7" + 6.1" screenshots** generated from in-app captures (re-shoot mockups in the real running app, not from `Product UI/` Tailwind exports).
- [ ] **1024×1024 app icon** from `anti_noise_minimal_wordmark` mockup, exported to `Assets.xcassets`.

## Beta + Submission

- [ ] **TestFlight internal build** uploaded; 5+ testers complete capture → summary → flashcard flow without confusion.
- [ ] **Crash-free sessions > 99%** in beta (Firebase Crashlytics dashboard).
- [ ] **No P0 bugs** outstanding from beta feedback.
- [ ] Submitted to **App Store Review**.

## Post-MVP (tracked, not blocking v1.0)

- Server proxy for OpenAI (Pro abuse mitigation — phase-11 R3).
- Full `Localizable.xcstrings` extraction via Xcode → Editor → Export For Localization. Current catalog covers paywall + onboarding + tab/profile shells only; long-form copy (Delete account, error messages, banner content) is still hardcoded English.
- Share Extension capture telemetry (`capture_created` with `source = share_ext`). Requires linking Firebase Analytics to the extension target + IPC to share consent state.
- iOS Focus Filter integration.
- Widget + Watch app.
- FSRS migration (replace SM-2).
- Per-UID dedup for trial-expiry sheet is already in place; `trial_started` + `subscription_started` are deduped via UserDefaults keyed on RC appUserID.

## Known accepted risks

- **OpenAI API key in client**: Apple has not historically rejected for this. v1.1 will move to a server proxy.
- **Timezone-change daily quota gaming**: date keys are local-time. Acceptable per phase-11 R4.
- **Apple intro offer eligibility**: re-installs on the same Apple ID won't get a fresh 7-day trial — expected behavior; UI conditionally states eligibility.
