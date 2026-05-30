---
phase: 7
title: "Polish Tests & ASC"
status: completed
priority: P2
effort: "3d"
dependencies: [6]
---

# Phase 7: Polish Tests & ASC

## Overview
Tests (unit + migration + smoke), polish UX, cập nhật privacy/ASC metadata cho data mới (Reddit articles, signals, daily inbox), chuẩn bị App Store review + "what's new".

## Requirements
- Functional: test coverage cho rank parsing, layered scheduling, quota, seed selection, migration legacy; ASC privacy nutrition cập nhật; what's-new copy.
- Non-functional: no failing tests; ASC review pass.

## Architecture
- Test layer: backend (rank/fallback), iOS (scheduler, quota, seed). Migration test trên build có data v1.0.
- ASC: data mới gửi/thu (Reddit article metadata, user signals, daily inbox) → cập nhật privacy policy + App Privacy nutrition labels.

## Related Code Files
- Create: tests cho `SpacedRepetitionScheduler` layered, `UsageQuotaService` article/lesson, `SeedDeckRepository` selection
- Create/Modify: backend tests cho `rankArticles` + fallback (`backend/`)
- Modify: `docs/legal/privacy-policy.md` (Reddit fetch, signals, daily_inbox)
- Modify: `ASC_METADATA.md` (what's new v1.1), App Privacy labels
- Modify: `docs/product-roadmap.md` (v1.1 status → shipped khi done)

## Implementation Steps
1. Unit: layered **ordering** (queue order Recognize→Recall→Apply; force-15 / thin-source fallback); quota article/lesson + reset window (incl iOS month bucket) + seed-exclude; seed select-by-pack + fallback.
2. Backend: rank prompt parse top-3, fallback khi Reddit/Gemini fail; cache TTL; `/v1/daily/refresh` auth (cross-uid/unauth → 401/403) + server quota gate + circuit-breaker; Firestore rules owner-only.
3. **Migration test (CRITICAL)**: boot store có data v1.0 với schema mới (`layerIndex`/`isLayered` literal defaults) → KHÔNG `fatalError`, deck cũ review bình thường, capture cũ không retro-gen.
4. Device smoke E2E: onboarding (topic packs req) → first-run articles → study this → 15 layered cards (ordering) → quota hit → paywall.
5. Polish: empty/skeleton/error copy (missing vs empty vs error inbox), loading timing (>8s "Almost there"), push copy, SSRF URL-validation check, accessibility pass.
6. ASC: privacy policy + nutrition labels (Reddit articles, signals, daily_inbox), what's-new copy. (UI redesign tách v1.1.1 → screenshots đổi ở v1.1.1, không phải đây.)
7. Fix failing tests tới khi xanh (delegate tester nếu cần). Update roadmap status.

## Success Criteria
- [ ] Tất cả unit/integration test pass (không skip/fake)
- [ ] Migration legacy deck verified không gãy
- [ ] E2E device path chạy trọn vẹn
- [ ] Privacy policy + ASC nutrition labels phản ánh data mới
- [ ] what's-new copy sẵn; roadmap v1.1 → shipped
- [ ] Build release pass, sẵn sàng submit

## Risk Assessment
- ASC reject do data disclosure thiếu (Reddit/signals) → cập nhật nutrition labels kỹ trước submit (lịch sử app từng bị reject ATT/EULA — xem [[anti-noise-next-steps]]).
- Migration là rủi ro cao nhất (live app) → test boot store v1.0 bắt buộc trước submit.
- 15-card AI cost margin → log thực tế, confirm projection ~$25/mo trước big launch.
