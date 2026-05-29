---
title: Anti Noise v1.1 — Daily Knowledge
description: >-
  Daily 3 articles (Reddit + Gemini rank) + Layered 15 flashcards (3-day Bloom
  journey) + Study-this + seed content. Big launch moment.
status: pending
priority: P2
branch: main
tags:
  - v1.1
  - daily-knowledge
  - ios
  - backend
blockedBy: []
blocks: []
created: '2026-05-29T04:58:07.422Z'
createdBy: 'ck:plan'
source: skill
---

# Anti Noise v1.1 — Daily Knowledge

## Overview

Thêm 2 retention mechanic vào MVP capture-on-demand: (a) daily content discovery (3 **skill/concept "đáng học thời AI"**/ngày từ **curated taxonomy + AI explainer**), (b) layered study (15 cards Recognize→Recall→Apply ordering) thay 1-shot. Cộng "Study this" nối item vào core loop + seed content fix cold-start. Big launch moment (PH/HN/Reddit).

> **Content-source đổi 2026-05-29:** Reddit-only → **curated skill taxonomy** (curriculum, KHÔNG news). Bỏ Reddit OAuth + fetch infra hoàn toàn. Lý do: định vị Daily Knowledge = "skills nên học thời AI", không phải feed tin. Supersedes locked decision #3 (Reddit-only, 2026-05-23). Red-team findings nay N/A: #8 SSRF (không fetch URL ngoài), #17 Reddit secret. Còn áp dụng: #2 route auth, #5 Firestore client net-new, #7 quota gate, #12 Firestore states+dedupe.

**Spec**: `docs/v1-1-daily-knowledge-spec.md` · **Roadmap**: `docs/product-roadmap.md`
**Depends**: v1.0.1 server proxy (✅ shipped). **Blocks**: v1.2 Deep Learn (cần layered-card infra của Phase 2).

## Key grounding (from codebase scout)

- `SM2Constants.maxCardsPerDeck = 15` đã sẵn; CardGenerator clamp 15 (`Core/Services/AI/CardGenerator.swift:112`). Cần thêm layer/day fields.
- Backend = Hono/Cloudflare Workers (`backend/src/index.ts`), proxy OpenRouter Gemini Flash. **Chưa có** Firestore document write (cần REST client mới). Reddit KHÔNG dùng (đổi sang curated taxonomy bundle trong Worker).
- iOS **chưa có** Firestore data-sync layer (chỉ account deletion chạm Firestore). `daily_inbox` cần read service mới.
- Onboarding 2 step hiện tại (`Features/Onboarding/OnboardingFlowView.swift`), store UserDefaults per-uid (`OnboardingStore.swift`). Topic packs = concept MỚI (khác `ClassificationScope` Personal/Work/Business).
- Notifications + StreakEngine sẵn sàng reuse (`Core/Services/Notifications/`). Streak đã đếm review-days → v1.1 không đụng.

## Phases

| Phase | Name | Status |
|-------|------|--------|
| 1 | [Onboarding Topic Packs (+ optional signals)](./phase-01-onboarding-signals-topic-packs.md) | Completed |
| 2 | [Layered 15 Flashcards (ordering, no lock)](./phase-02-layered-15-flashcards.md) | Completed |
| 3 | [Backend Daily Pipeline (curated skill taxonomy)](./phase-03-backend-daily-pipeline.md) | Completed |
| 4 | [iOS Daily Skills & Study This](./phase-04-ios-daily-articles-study-this.md) | Completed |
| 5 | [Seed Content (1-2 lessons)](./phase-05-seed-content.md) | Pending |
| 6 | [Quota & Paywall](./phase-06-quota-paywall.md) | Pending |
| 7 | [Polish Tests & ASC](./phase-07-polish-tests-asc.md) | Pending |

> **Redesign split out (red-team 2026-05-29):** Kinetic Command UI redesign (cũ P0+P8) tách sang plan **v1.1.1** riêng (visual-only, QA + rollback độc lập). v1.1 ship trên design system HIỆN TẠI. Mockups + design system: see [[reference-anti-noise-kinetic-command-design]].

## Dependency graph

```
P1 (topic packs) ──> P3 (backend rank) ──> P4 (iOS consume)
P2 (layered cards, ordering) ─┬─> P4 (Study this → gen cards)
                              └─> P5 (seed = layered decks)
P4, P5 ──> P6 (quota) ──> P7 (polish+tests+ASC)
```

P1+P2 parallel (no design-system dep — build trên UI hiện tại). P3 needs P1. P4 needs P1+P2+P3. P5 needs P2. P6 needs P4+P5. P7 last.

## Effort

~2 tuần dev + ~2 ngày (study-this/seed) + 3 ngày ASC = **~2 tuần** (khớp spec gốc sau khi cắt redesign+cron). See per-phase effort.

## Red Team Review

### Session — 2026-05-29
**Reviewers:** 4 (Security Adversary, Failure Mode Analyst, Assumption Destroyer, Scope & Complexity Critic). **Findings:** 19 after dedup (6 Critical, 9 High, 4 Medium). All evidence-backed (file:line).

**Disposition split:** Technical correctness/security → **Accepted & applied** to phase files (see "Red Team Corrections" blocks). Scope/YAGNI items that reverse user-confirmed decisions → **Deferred to user** (not auto-applied, per decision-guard rule).

#### Accepted & applied (technical)

| # | Finding | Sev | Applied |
|---|---------|-----|---------|
| 1 | No `firestore.rules`/`firebase.json` in repo — new `daily_inbox`/`users/{uid}` collections unsecured | Crit | Completed |
| 2 | `/daily/refresh` named outside `/v1/*` auth middleware → may ship UNauthenticated; uid must come from token not body | Crit | Completed |
| 3 | SwiftData migration unsafe: non-optional `unlockedAt: Date` w/ init-default → migration fails → `fatalError` crash-loop + data loss for live v1.0 users | Crit | Completed |
| 4 | Layered cards instantly due: new cards default `nextReviewAt=Date()`; `dueTodayCount` predicate has NO unlock filter → 15 cards flood Day 1 | Crit | Completed |
| 5 | Backend has ZERO Firestore read/write code (`firebase-admin.ts` = only `setUserTier`) — "extend" is net-new infra; effort underestimated | Crit | P3 |
| 6 | "Study this → 15 cards" FALSE: card gen is manual (`SummaryDetailView` CTA); `CaptureFlowModel.save()` only summarizes | Crit | P4 |
| 7 | `/daily/refresh` no server-side quota gate before Reddit/Gemini → cost-DoS drains shared Gemini key for all users | High | P3 |
| 8 | SSRF: Reddit-sourced article URLs → `ReadabilityExtractor` fetch w/ no scheme/host validation (file://, internal hosts, prompt-injection) | High | P4 |
| 9 | Phase 0 no-op risk: colors live in `Assets.xcassets` colorsets (not `AppColor.swift`); `AppFont` uses `.system` (no `Font.custom`) | High | P0 |
| 10 | Quota KV peek/commit non-atomic (no CAS) + lesson/article enforced client-side only → double-tap & direct-call bypass | High | P6 |
| 11 | Cron: no idempotency/partial-failure cursor/hard Gemini ceiling; no `lastActiveAt` field exists; per-user-rank vs shared-pool cost contradiction | High | P3 |
| 12 | Firestore missing-doc (common case) vs empty vs error undefined; "Study this" no dedupe → double Capture/Deck/quota | High | P4 |
| 13 | Cron infra missing: `export default app` has no `scheduled()`; `wrangler.toml` has no `[[triggers.crons]]` (file is 41 lines, plan cited :42) | High | P3 |
| 14 | Layered prompt: backend `FLASHCARDS_SYSTEM_PROMPT` makes 3-15 by density (not 15); needs force-15/5-5-5 + thin-source fallback; "5→15" framing wrong (baseline 3-15) | High | P2 |
| 15 | Existing v1.0 users (onboarding done) never re-onboard → no signals doc → generic articles; need `signalsVersion` backfill | Med | P1 |
| 16 | iOS `UsageQuotaService` has only daily counter; `.lesson` 3/month needs new month-window counter | Med | P6 |
| 17 | Reddit token must NOT colocate in `RATE_LIMIT` KV (leak risk); dedicated store + never-log | Med | P3 |
| 18 | Unlock push one-shot interval doesn't survive clock/timezone change → use `UNCalendarNotificationTrigger` absolute + reschedule on foreground | Med | P2 |
| 19 | Several stale `file:line` anchors (wrangler:42, firebase-admin:77-100, CaptureFlowModel reuse claim) → re-verify before edit | Med | all |

#### Scope/YAGNI — user-resolved 2026-05-29

| Finding | Reviewer claim | Resolution |
|---------|----------------|------------|
| A. Split redesign (P0+P8) | ~40% scope creep vs 2-week spec | **ACCEPTED** → moved to plan v1.1.1; v1.1 on current design system |
| B. Cut XP/SkillRadar shells | Gold-plating, over-promise | **ACCEPTED** → removed (was in P8, now gone) |
| C. Drop 3-day lock, keep ordering | Lock blocks owned cards; flaky time tests | **ACCEPTED** → P2 = layer ordering only, no time-lock/countdown/unlock-push |
| D. Signals optional | 6-screen onboarding → 10-20% drop-off | **ACCEPTED** → P1 requires topic packs only; role/level/goal optional (post-onboarding in Profile) |
| E. Collapse "Study this" to 1 button | Both options same pipeline | **KEPT 2 options** (user's Feynman-also-cards decision stands); revisit at build if confusing |
| F. Defer cron batch | Premature for soft-launch (200-700 signups/90d) | **ACCEPTED** → P3 on-demand only; cron deferred |
| G. Seed 1-2 lessons | 75 hand-QA'd cards content-heavy | **ACCEPTED** → P5 = Productivity + 1 popular pack + fallback |

Net effect: 9 phases → 7; ~3.5 weeks → ~2 weeks (back to committed spec scope). Redesign + cron deferred, not cancelled.

## Dependencies

Blocks `v1.2 Deep Learn` (separate spec, not yet planned) — Phase 2 layered-card mechanic (Bloom ordering) is reused there. Note: v1.2 Deep Learn originally assumed 3-day lock/unlock infra from here; with lock cut (red-team C), Deep Learn must implement its own day-pacing — flag when planning v1.2.
Related: redesign split → plan **v1.1.1** (Kinetic Command). v1.2 Deep Learn depends on v1.1 card mechanic.
