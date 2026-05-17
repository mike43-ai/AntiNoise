# Next Steps — Anti Noise

State at 2026-05-17: all 12 phases code-complete. Working tree clean, `f8b26eb` is HEAD. Project regenerated via `xcodegen generate` and opened in Xcode.

For the full operational checklist (ASC products, screenshots, TestFlight, submission) see `LAUNCH_CHECKLIST.md`.

## Right now

1. **Cmd+B in Xcode** — let SPM resolve, then build. Phase 12 changed many files; expect possible import/env-injection issues. Fix anything that breaks.
2. **Cmd+R on simulator** — golden path smoke test:
   - Sign up (email or Apple) → onboarding profile step → new notification permission step
   - Capture (URL / note / image) → see Feynman summary
   - Tap "Create flash cards" → review session → check streak counter
   - Open Profile → verify Pro/Free section, notification settings, privacy toggles

## Today / this week

3. Drop **`GoogleService-Info.plist`** into `AntiNoise/Resources/` (Firebase Console → iOS app). Without it: Auth + Analytics + Crashlytics are no-ops.
4. Add **`RCAppPublicKey`** to `AntiNoise/Resources/Info.plist` (RevenueCat dashboard → API keys, public). Without it: `isPro` stays false forever.
5. Set **`DEVELOPMENT_TEAM`** in `project.yml`, then `xcodegen generate` again. Required for keychain access on real devices.

## Pre-submission

6. Create Pro monthly + annual SKUs in App Store Connect with 7-day intro on monthly. Product IDs must match the RC offering.
7. Generate 1024×1024 icon + 6.7"/6.1" screenshots from the running app.
8. Fill App Store metadata (Productivity primary / Education secondary, VI + EN copy).
9. Provision demo account with sample captures + Pro entitlement for Apple Review.
10. Flip `aps-environment: production` in `project.yml`, regenerate, archive.
11. TestFlight beta (≥1 week, ≥5 testers, watch Crashlytics for ≥99% crash-free sessions).
12. Submit to App Store Review.

## Known accepted risks (locked, don't re-open)

- OpenAI key in client — v1.1 server proxy is the plan.
- Timezone gaming of daily quotas — acceptable for MVP.
- Apple intro-offer eligibility on re-installs — UI states it conditionally.
- Localizable.xcstrings only covers paywall / onboarding / tab / Profile shells. Long-form copy is still EN-only.

## Cross-references in repo

- `LAUNCH_CHECKLIST.md` — full external launch checklist
- `plans/20260516-1500-anti-noise-ios-mvp/plan.md` — phase-by-phase status table
- `plans/20260516-1500-anti-noise-ios-mvp/reports/code-review-phase-11-paywall.md`
- `plans/20260516-1500-anti-noise-ios-mvp/reports/code-review-phase-12-launch.md`
