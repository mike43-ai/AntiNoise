---
phase: 3
title: "Backend Daily Pipeline (on-demand only)"
status: pending
priority: P1
effort: "3d"
dependencies: [1]
---

# Phase 3: Backend Daily Pipeline (on-demand only)

## Overview
Backend Cloudflare Worker: `POST /v1/daily/refresh` (single uid, từ token) → fetch Reddit top-of-day theo topic packs → Gemini Flash rank top 3 → ghi Firestore `daily_inbox/{uid}/{date}`. **On-demand only** — cron batch DEFER (red-team F: premature cho soft-launch 200-700 signup/90d).

> Red-team 2026-05-29: cron 6AM batch + active-users query + lastActive field + batch concurrency CẮT. Chỉ giữ on-demand (app-open / first-run / nút refresh) — đủ cho scale hiện tại.

## Requirements
- Functional: refresh theo uid (từ token); rank dùng topic packs (+ signals nếu có, P1); ghi inbox; fallback khi Reddit/Gemini fail.
- Non-functional: server-side quota gate + circuit-breaker trước fetch; Reddit free OAuth + KV cache per-sub/hour; security (auth, rules).

## Architecture
- Stack: Hono + CF Workers (`backend/src/index.ts`), OpenRouter proxy sẵn (`openrouter-client.ts`).
- **Net-new (KHÔNG phải "extend")**: Firestore REST client + Reddit client + rank function + Firestore rules. `firebase-admin.ts` hiện chỉ có `setUserTier` (100 dòng, 0 Firestore code) — reuse được DUY NHẤT token-mint scope `firebase` (line 38).
- Flow per uid: đọc signals (nếu có) → fetch candidates theo packs → Gemini rank → ghi inbox.

## Related Code Files
- Create: `backend/src/firestore-client.ts` (REST get/commit cho Workers — get `users/{uid}`, commit `daily_inbox/{uid}/{date}`)
- Create: `backend/src/reddit-client.ts` (OAuth app-only, fetch top/day per subreddit)
- Create: `backend/src/daily-pipeline.ts` (orchestrate fetch→rank→write per uid)
- Create: `firestore.rules` (commit vào repo — owner-only)
- Modify: `backend/src/openrouter-client.ts` (`rankArticles()` + `RANK_SYSTEM_PROMPT`)
- Modify: `backend/src/index.ts` (route `POST /v1/daily/refresh` DƯỚI `/v1/*` auth middleware)
- Modify: `backend/wrangler.toml` (Reddit secrets; KV cache — namespace riêng, KHÔNG chung `RATE_LIMIT`)

## Implementation Steps
1. **Firestore REST client** (`firestore-client.ts`): reuse token-mint, thêm `getDoc`/`commitDoc`; field-value codec. (Đây là phần effort chính — không có sẵn.)
2. **`firestore.rules`** + commit: `match /users/{uid} { allow read,write: if request.auth.uid==uid }`; `match /daily_inbox/{uid}/{date} { allow read: if request.auth.uid==uid; allow write: if false }` (write = admin SDK). Deploy = hard gate trước device test P4.
3. **Reddit client**: OAuth app-only (client_credentials); `/r/{sub}/top?t=day`; cache token (in-memory/KV riêng, never-log) + per-sub results (KV TTL 1h).
4. **`RANK_SYSTEM_PROMPT`** + `rankArticles()`: input topic packs (+ role/level/goal nếu có) + 30 candidate → score 4 tiêu chí → top 3 + reason (JSON).
5. **`POST /v1/daily/refresh`**: DƯỚI auth middleware; `uid = c.get('user').uid` (KHÔNG từ body). Server-side quota: `peekUsage`/`commitUsage` bucket `usage:{uid}:refresh:{date}` (free 1 / pro 3) + global circuit-breaker `gemini:global:{date}` TRƯỚC fetch. Gọi pipeline, return 3 articles.
6. **Fallback**: Reddit timeout >5s → top-of-week cached pool; Gemini fail/limit → top-3 by upvote (unranked); circuit-breaker hit → cached/seed fallback. Log (không log secret).
7. Deploy preview, test refresh với 1 uid thật + test cross-uid/unauth → 401/403.

## Success Criteria
- [ ] `POST /v1/daily/refresh` (authenticated) trả 3 ranked articles, ghi `daily_inbox/{uid}/{date}`; cross-uid/unauth → 401/403
- [ ] `firestore.rules` committed + deployed; chỉ owner đọc inbox/signals
- [ ] Server-side quota gate + circuit-breaker chặn cost-DoS trước khi gọi Reddit/Gemini
- [ ] Rank phản ánh packs (+ signals nếu có); fallback không crash
- [ ] Reddit token không lộ (không KV chung, không log); deploy wrangler OK

## Risk Assessment
- **[Crit] Firestore REST + rules = net-new** → effort thật ≈ 3d (không phải "extend"); ưu tiên client + rules trước.
- **[Crit] Auth/route**: phải `/v1/` prefix + uid từ token, nếu không → unauth + cross-user poisoning (admin SDK bypass rules).
- Reddit rate limit → KV cache per-sub/hour; share candidate pool theo pack.
- Gemini free 1500/day → circuit-breaker + fallback; on-demand only nên tải thấp hơn cron.
- Subreddit chết/private → skip + log, đừng fail cả pack.
- Cron defer: nếu sau này cần pre-warm → thêm `scheduled()` handler + `export default {fetch,scheduled}` + `[[triggers.crons]]` + `lastActiveAt` field + idempotency (ghi rõ để v.sau làm).