---
title: "v1.3 Ascent — gamified climb"
description: "A 60-day mountain expedition tab where users earn elevation ONLY from real learning. Client-side MVP, seasons, minimalist topographic."
status: pending
priority: P2
branch: "v1.2-deep-learn"
tags: [ios, swiftdata, gamification, retention, tab]
blockedBy: [20260530-v1-2-deep-learn]
blocks: []
created: "2026-05-30T13:45:59.698Z"
createdBy: "ck:plan"
source: skill
---

# v1.3 Ascent — gamified climb

## Overview

Fill the empty Focus-tab slot (app returns to 5 tabs) with **Ascent**: a 60-day mountain
"expedition" where every act of *real learning* earns elevation toward a summit. Drives the core
flywheel (review due cards, do Deep Learn) and adds a medium-term, repeatable (seasonal) retention
goal. **Reward learning only** — never add-topic / card-flip / hoarding (would fight SRS + the
Anti-Noise anti-hoarding brand).

Brief: `docs/v1-3-ascent-spec.md` (full spec, locked decisions, tunable economy, open questions).
This plan is the implementation breakdown. **No new backend** for MVP — reuse existing learning
events + StreakEngine; Firestore mirror only (pattern: `LearningPathSyncService`).

## Dependency
- **Ships AFTER v1.2 (Deep Learn)** — already merged to `main`. Ascent credits elevation from
  `learnDayCompleted` (Deep Learn) + needs real v1.2 usage data to tune the economy before locking
  constants. `blockedBy: 20260530-v2-deep-learn`.

## Phases

| Phase | Name | Status |
|-------|------|--------|
| 1 | [Tab + data model + persistence](./phase-01-tab-data-model-persistence.md) | Pending |
| 2 | [Elevation economy + service + hooks](./phase-02-elevation-economy-service-hooks.md) | Pending |
| 3 | [Ascent tab UI](./phase-03-ascent-tab-ui.md) | Pending |
| 4 | [Milestones + seasons + trophy room](./phase-04-milestones-seasons-trophy-room.md) | Pending |
| 5 | [Telemetry + altitude report + tests](./phase-05-telemetry-altitude-report-tests.md) | Pending |

## Sequencing invariant
App compiles between every phase. P1 adds the `.ascent` tab showing a placeholder until P3 swaps the
real UI. P2 (economy/service) is logic-only and can land before the UI exists.

## Key decisions (from spec, locked 2026-05-30)
1. **Reward learning only** — due reviews, review-session complete, Deep Learn day, streak multiplier.
2. **Dedicated tab** (5 tabs), seasons (repeatable 60-day expeditions), minimalist topographic visual.
3. **Client-side MVP**, no leaderboard (defer — would require server anti-cheat).
4. **Economy constants are tunable** (a single `AscentEconomy` constants type) — balancing is the
   make-or-break, tuned from v1.2 data, NOT hardcoded across the codebase.

## Constraints
- Swift 5.9-compat (Xcode 15.2 ceiling): no `@Previewable`, no implicit `@MainActor` tricks.
- Each Swift file < 200 lines; PascalCase; follow existing `AntiNoise/` patterns.
- SwiftData additive migration (literal defaults; new entities are additive-safe — proven by
  `DailySkillItem` / `LearningPath`).

## Open questions (defer; from spec — tune post-v1.2-data)
1. Per-action elevation + summit target — starter numbers in spec, tune from real usage.
2. Leaderboard/social in MVP? (default: defer.)
3. Camp unlocks cosmetic vs functional?
4. Miss summit by day 60 → partial credit / head-start, or clean reset?
