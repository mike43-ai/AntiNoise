---
title: "Anti Noise v1.1.1 — Kinetic Command Redesign"
description: "Visual-only redesign toàn app theo Stitch Kinetic Command (Soft Stone + Vibrant Orange + Space Grotesk + glassmorphic dock). Split from v1.1 per red-team 2026-05-29."
status: pending
priority: P2
branch: "main"
tags: [v1.1.1, ui, redesign, kinetic-command]
blockedBy: [20260529-1157-v1-1-daily-knowledge]
blocks: []
created: "2026-05-29T05:43:17.736Z"
createdBy: "ck:plan"
source: skill
---

# Anti Noise v1.1.1 — Kinetic Command Redesign

## Overview
Redesign toàn app theo Stitch "Kinetic Command" design system. **Visual-only** — không đổi logic/feature. Tách khỏi v1.1 (red-team 2026-05-29: tránh ~40% scope creep + bề mặt regression lớn trên 1 launch). Ship sau v1.1 → QA + rollback độc lập.

**Design source**: `/Users/huyai/Downloads/stitch_careerpath_ai_copilot 2/` (DESIGN.md + 3 mockup). See [[reference-anti-noise-kinetic-command-design]].
**Blocked by**: v1.1 (`20260529-1157-v1-1-daily-knowledge`) — redesign các màn SAU khi v1.1 thêm xong (article grid, layered card) để khỏi redo.

## Scope decisions (red-team 2026-05-29)
- **Visual shell XP/SkillRadar → CẮT** (red-team B). Profile chỉ dùng data thật: streak (StreakEngine), completed count, weekly review chart (StatsAggregator). KHÔNG XP badge, KHÔNG skill radar giả.
- Gamification thật (XP/radar) → version sau khi có spec + data model.
- Tab naming mockup (Focus/Learn/Plan/Profile) CHƯA chốt (đụng v1.2 gỡ Focus) → giữ tab hiện tại, chỉ đổi style dock.

## Phases

| Phase | Name | Status |
|-------|------|--------|
| 1 | [Design System Foundation](./phase-01-design-system-foundation.md) | Pending |
| 2 | [Screen Redesign](./phase-02-screen-redesign.md) | Pending |

## Dependency graph

```
v1.1 ships ──> P1 (tokens/font/components) ──> P2 (redesign all screens)
```

P1 trước P2. Cả 2 sau khi v1.1 ship (build trên màn v1.1 final).

## Effort
~1.5 tuần (P1 3d + P2 4d + QA/ASC). Visual-only → ASC review nhẹ hơn.

## Dependencies
blockedBy v1.1 daily-knowledge (redesign final screens incl. article grid + layered card view).
