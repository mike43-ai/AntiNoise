---
phase: 6
title: Quota & Paywall
status: completed
priority: P2
effort: 2d
dependencies:
  - 4
  - 5
---

# Phase 6: Quota & Paywall

## Overview
Thêm quota article (Free 1/day) + lesson (Free 3/month), Pro unlimited. Seed lesson `isSample` KHÔNG tính. Mở rộng cả iOS local guard + backend rate-limiter; paywall trigger khi hit.

## Requirements
- Functional: Free 1 article/day + 3 lessons/month + 3 captures/day (giữ); Pro unlimited; seed excluded; QuotaHitSheet messaging cho article/lesson.
- Non-functional: peek-then-commit (chỉ trừ khi thành công); reset đúng day/month boundary.

## Architecture
- iOS `UsageQuotaService` (UserDefaults, `.capture`/`.aiSummary` sẵn) → thêm `.article`, `.lesson`. Pro skip (đã có pattern).
- Backend `rate-limiter.ts` (KV peek/commit) → thêm `freeArticleLimit`, `freeMonthlyLessonLimit`.
- "Lesson" = 1 lần gen layered deck (Study this hoặc capture deep-dive). Seed deck `isSample` → bỏ qua consume.
- Paywall reuse `QuotaHitSheet` + `PaywallSheetView`.

## Related Code Files
- Modify: `AntiNoise/Core/Services/Subscription/UsageQuotaService.swift:6-16` (enum `.article`/`.lesson` + freeLimit + reset window)
- Modify: `backend/src/rate-limiter.ts:6` (config + bucket cho article/lesson)
- Modify: `AntiNoise/Core/Services/AI/CardGenerator.swift` (consume `.lesson` khi gen, skip nếu `isSample`)
- Modify: `AntiNoise/Core/Services/Daily/DailyInboxService.swift` (consume `.article` khi Study this; refresh free 1/day)
- Modify: `AntiNoise/Features/Paywall/QuotaHitSheet.swift:4-64` (copy cho article/lesson)

## Implementation Steps
1. `UsageQuotaService`: `.article` (free 1/day, reset UTC-midnight local), `.lesson` (free 3/month, reset month). Pro → `.max`.
2. Backend `rate-limiter.ts`: bucket `usage:{uid}:article:{date}`, `usage:{uid}:lesson:{month}`; peek trước, commit sau success.
3. `CardGenerator.generate`: nếu `!isSample` → `canConsume(.lesson)`; hit → trả quotaExceeded (parent show QuotaHitSheet); consume sau gen OK.
4. `DailyInboxService`: Study-this article → `.article` consume; cron/free refresh tôn trọng 1/day free (Pro 3).
5. Seed path bỏ qua mọi consume (`isSample`).
6. QuotaHitSheet: 2 message mới ("Daily article limit", "Monthly lesson limit") + "See Pro plan".
7. Compile + test free hit → paywall; Pro unlimited; seed không trừ.

## Success Criteria
- [ ] Free: 1 article/day, 3 lessons/month enforced; hit → QuotaHitSheet → paywall
- [ ] Pro: unlimited, không bị chặn
- [ ] Seed lesson KHÔNG trừ quota
- [ ] Consume chỉ sau khi gen/refresh thành công (peek-then-commit)
- [ ] Reset đúng day/month boundary; build pass

## Risk Assessment
- Lệch iOS local vs backend KV → backend là source of truth chống abuse; iOS chỉ guard UX. Đồng bộ limit value.
- Định nghĩa "lesson" mơ hồ → chốt = 1 lần gen layered deck (không phải mỗi card). Document rõ.
- Pricing $9.99 giữ (review sau data v1.1) — không đổi ở phase này.

## Red Team Corrections (2026-05-29)
- **[High] Quota bypass + race**: `.lesson` gate ở iOS `UsageQuotaService` (UserDefaults, client-trusted) nhưng `/v1/ai/flashcards` (`index.ts:178-220`) chỉ commit MONTH bucket → modified client / direct call sinh deck vô hạn tới trần 10/tháng. KV `commitUsage` (`rate-limiter.ts:66-80`) là get→+1→put KHÔNG atomic (KV no CAS) → double-tap = 2 lesson/1 slot. FIX: enforce `.lesson`/`.article` SERVER-side (`usage:{uid}:lesson:{month}`, `usage:{uid}:article:{day}`) trong handler; `resolveBucket` nhận kind param; idempotency-key cho refresh+lesson-gen; iOS chỉ UX-guard. Acceptance: direct backend call quá limit → 429.
- **[Med] iOS thiếu monthly counter**: `UsageQuotaService` (`:6-16`) chỉ reset theo ngày → `.lesson` 3/month sẽ thành 3/ngày. FIX: thêm month-window counter (parity với backend `monthBucket`).
