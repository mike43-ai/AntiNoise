---
title: "ANTI NOISE — iOS MVP Implementation"
description: "iOS app + share extension that captures info, AI-summarizes via Feynman method, and turns deep-dives into flash cards."
status: in_progress
priority: P2
effort: 22d
branch: main
tags: [ios, swiftui, firebase, openai, revenuecat, learning, mvp]
created: 2026-05-16
---

# ANTI NOISE — iOS MVP

**Tagline:** Cut The Noise — Focus on What Matters.

**Scope locked:** Free (3 captures/day + 5 AI summaries/mo) vs Pro (unlimited) with 7-day Pro trial on first launch · Email/password + Apple Sign-In only · GPT-4o vision (no OCR fallback) · SwiftData local-first + Firestore mirror · SM-2 spaced repetition · VI + EN at launch · Firebase Analytics only · Productivity (primary) / Education (secondary).

**Stack:** Swift 5.10, SwiftUI, iOS 17+, SwiftData, Firebase (Auth + Firestore + Analytics + Crashlytics), OpenAI GPT-4o, RevenueCat, Share Extension (UIKit entry).

**Architecture:** MV with `@Observable` view models. Feature-folder structure under `AntiNoise/Features/{Home,Learn,Capture,Focus,Profile,Auth,Onboarding}`. Shared layer: `AntiNoise/Core/{DesignSystem,Persistence,Services,Networking,Models}`. Local-first SwiftData store; Firestore mirror for cross-device sync.

## Phases

| # | Title | Effort | Status |
|---|-------|--------|--------|
| 01 | Project setup, Xcode workspace, SPM deps | 1d | completed (build-verify deferred — disk full) |
| 02 | Design system tokens + reusable components | 2d | pending |
| 03 | Firebase Auth (email + Apple) | 1.5d | pending |
| 04 | Tab navigation shell (5 tabs) | 1d | pending |
| 05 | Capture flow + Share Extension | 2.5d | pending |
| 06 | OpenAI Feynman summary service | 2d | pending |
| 07 | Classification + daily priority engine | 2d | pending |
| 08 | Flash cards + spaced repetition (SM-2) | 3d | pending |
| 09 | Focus mode (timer + session) | 1.5d | pending |
| 10 | Home dashboard + Profile screens | 2d | pending |
| 11 | RevenueCat paywall + subscription gating | 1.5d | pending |
| 12 | Polish, telemetry, launch readiness | 2d | pending |

**Total effort:** ~22 days (single dev).

## Key Dependencies (cross-phase)

- 02 blocks 04–10 (UI tokens drive every screen)
- 03 blocks 05–11 (user identity needed for cloud sync, paywall attribution)
- 06 blocks 07, 08 (AI output feeds classification + cards)
- 11 can begin in parallel with 09–10 once 03 done

## UI Mockup Inventory

All under `Product UI/`:

- `anti_noise_landing_page_updated_hero/screen.png` — onboarding/landing
- `anti_noise_minimal_wordmark/screen.png` — brand wordmark
- `import_profile/screen.png` — sign-in / first-run profile import
- `ai_connection_anti_noise/screen.png` — AI-status / connection indicator
- `refined_quick_capture_flow/screen.png` — Capture tab flow
- `anti_noise_feynman_insight_distillation/screen.png` — AI summary detail
- `simplified_learn_hub_anti_noise/screen.png` — Learn tab hub
- `flashcard_learning_view/screen.png` — Flash card study session
- `focus_session_setup_anti_noise/screen.png` — Focus tab session setup
- `career_goals_anti_noise/screen.png` — Goals / classification scope
- `professional_profile_progress/screen.png` — Profile tab w/ progress
- `kinetic_command/screen.png` — command palette / quick actions

Each mockup folder also contains `code.html` (Tailwind reference) — treat as visual ground truth, re-implement in SwiftUI.

## Resolved Decisions (locked 2026-05-16)

| # | Topic | Decision |
|---|-------|----------|
| 1 | Tier model | 7-day Pro trial on first launch → on expiry user falls to Free (3 captures/day + 5 AI summaries/month) OR converts to Pro (unlimited). |
| 2 | Image AI pipeline | GPT-4o vision endpoint only. No on-device Vision OCR. No fallback path. |
| 3 | Paywall triggers | Trial-expiry sheet + quota-hit sheet (capture cap or AI cap). No onboarding paywall, no post-onboarding hard wall. |
| 4 | App Store category | Primary: Productivity. Secondary: Education. |
| 5 | Offline mode | Capture writes to SwiftData immediately offline; AI-summary job enqueued + retried with exponential backoff when network returns. |
| 6 | Sync | SwiftData local-first + Firestore mirror for cross-device sync. SwiftData is source of truth on-device; Firestore reconciles. |
| 7 | SRS algorithm | SM-2 (Anki classic). EF default 2.5, EF min 1.3, intervals [1, 6, prev*EF]. |
| 8 | Flashcards per deep-dive | AI-decided 3–15 based on content density. Prompt instructs model to pick count. |
| 9 | Push notifications | Daily review reminder + streak nudge. Both opt-in at first notification prompt (post-onboarding). |
| 10 | Localization | Vietnamese + English at launch. String Catalogs (`Localizable.xcstrings`). |
| 11 | Analytics | Firebase Analytics only. No PostHog. |
| 12 | Share extension content types | URL + text + image (all three). |
| 13 | Auth providers | Email/password + Apple Sign-In only. No Google, no SMS. |
| 14 | Account deletion | Profile → Settings → Delete Account. JSON data export pre-deletion + 7-day grace (soft-delete then hard-delete). |
| 15 | Feynman prompt schema | Structured JSON output, 5 sections: `simple_explanation`, `analogy`, `knowledge_gaps`, `examples`, `deeper_question`. |

## Unresolved Questions

None at plan-lock. New questions surfaced during implementation:

- **Phase 01 — `associated-domains` deferred.** Re-enable in phase 08 once `antinoise.app` is provisioned and AASA is hosted.
- **Phase 01 — Simulator runtime install blocked by disk-full.** Re-run `xcodebuild -downloadPlatform iOS` after freeing ≥10 GB to verify the build.
