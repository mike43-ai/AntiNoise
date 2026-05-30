---
title: "Anti Noise v1.2 — Deep Learn (replaces Focus)"
description: "Remove Focus, add Pro-gated 7-day mastery course (outline-first, lazy gen, open pacing) in the Learn tab."
status: pending
priority: P2
effort: ~2-3 weeks
branch: main
tags: [ios, swiftdata, cloudflare-worker, deep-learn, focus-removal, pro]
created: 2026-05-30
---

# Anti Noise v1.2 — Deep Learn

Replace the Focus (Pomodoro) feature with **Deep Learn**: a Pro-only, 7-day mastery course that
extends the value ladder `capture → summarize → flashcard → MASTERY COURSE`. Lives in the existing
Learn tab. Course content is hybrid (seed from user captures, else Gemini), generated **outline-first
+ lazy per day**, with **open pacing** (no time-gate — all 7 days available immediately; each day's
heavy content lazy-generates on open).

Primary brief: `docs/v1-2-deep-learn-spec.md`. Spec corrections (verified against live code) are in
`reports/scout-corrections.md` and override the spec where they conflict.

## Dependency
- **v1.1 must ship first** — Deep Learn reuses layered-card generation (Recognize/Recall/Apply),
  the OpenRouter proxy, and SM-2 SRS from v1.1. v1.1 is code-complete, TestFlight build 20.

## Phases

| # | Phase | Status | Depends |
|---|-------|--------|---------|
| 01 | [Remove Focus + streak migration + telemetry](phase-01-remove-focus-streak-telemetry.md) | pending | — |
| 02 | [Data model + persistence + Firestore mirror](phase-02-data-model-persistence-firestore.md) | pending | 01 |
| 03 | [Backend: /learn/path + /learn/day + prompts + tests](phase-03-backend-endpoints-prompts-tests.md) | pending | — |
| 04 | [iOS Deep Learn UI + lesson flow](phase-04-ios-deep-learn-ui-lesson-flow.md) | pending | 02, 03 |
| 05 | [Pro-gate + paywall wiring](phase-05-pro-gate-paywall-wiring.md) | pending | 04 |
| 06 | [Docs removal checklist + ASC](phase-06-docs-removal-checklist-asc.md) | pending | 01, 04 |
| 07 | [Tests + polish](phase-07-tests-and-polish.md) | pending | 04, 05 |

## Sequencing invariant
The app **must compile between every phase**. Phase 01 removes the Focus tab and replaces it with a
placeholder "Deep Learn — coming soon" section in the Learn tab so the build never breaks. Phase 04
swaps the placeholder for the real UI. Phase 03 (backend) is independent and can run in parallel with
01–02.

## Key corrections applied (override the spec)
1. **Open pacing, no lock/countdown/unlock.** No `unlocksAt`, no countdown UI, no unlock push.
   Verified: zero `unlocksAt`/`isLocked` in codebase.
2. **No cron.** Day content generated on-open via `POST /v1/learn/day`. Cron pre-gen deferred.
3. **Notification infra already exists** (`Core/Services/Notifications/`). Reuse it; do NOT extract
   from FocusSessionEngine. A daily reminder is optional/deferred.
4. **Streak partly migrated already.** `StreakEngine` (review-based) exists and is already called on
   review completion. Migration = repoint the *displayed* stat off `FocusSession`. See phase 01.

## Defaults for open questions (flagged for user review)
- 14-day course: **deferred entirely** (7-day only).
- Abandoned path **keeps** its already-generated cards in the SRS queue.
- Completion = simple "Mastered [topic] in 7 days 🏆" badge; share-card **deferred**.

## Constraints
- Swift 5.9-compat only (Xcode 15.2 ceiling): no `@Previewable`, no implicit `@MainActor` tricks.
- Each Swift file < 200 lines; PascalCase; follow existing `AntiNoise/` patterns.
- Backend: TS strict; reuse `rate-limiter.ts` peek/commit, `firebase-token-verifier.ts`,
  `firestore-client.ts`, `openrouter-client.ts`. Add vitest tests.

## Unresolved questions
See `reports/scout-corrections.md` → "Unresolved questions" and each phase's Risk section.
