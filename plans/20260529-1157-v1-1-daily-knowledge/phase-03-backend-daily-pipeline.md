---
phase: 3
title: Backend Daily Pipeline (curated skill taxonomy)
status: completed
priority: P1
effort: 2-3d
dependencies:
  - 1
---

# Phase 3: Backend Daily Pipeline (curated skill taxonomy)

## Overview
Backend Cloudflare Worker: mỗi user (on-demand) → chọn 3 **skill/concept "đáng học thời AI"** chưa xem từ **curated taxonomy** (theo topic packs + signals), Gemini sinh explainer ("why it matters now" + core concept), ghi Firestore `daily_inbox/{uid}/{date}`. **KHÔNG Reddit** (decision 2026-05-29: đổi từ Reddit-only → curated taxonomy + AI explainer).

> Đổi nguồn 2026-05-29: Daily Knowledge = curriculum (skills nên học), KHÔNG phải news. Bỏ Reddit OAuth + fetch infra hoàn toàn → gỡ blocker creds. On-demand only (cron defer, red-team F).

## Requirements
- Functional: pick 3 skill chưa xem theo packs (+ personalize bằng role/level/goal nếu có); Gemini explainer mỗi item; track "seen" tránh lặp; ghi inbox; "all caught up" khi hết.
- Non-functional: zero external content API/creds; server-side quota gate trước Gemini; Firestore owner-only rules.

## Architecture
- Stack: Hono + CF Workers (`backend/src/index.ts`), OpenRouter proxy sẵn (`openrouter-client.ts`).
- **Taxonomy = bundle trong Worker** (`backend/src/skill-taxonomy.ts`), version-controlled, update qua redeploy. KHÔNG DB. Per topic pack → list `{ id, title, keyword, seedNote }` (skill/concept thời AI: vd AI/ML → RAG, evals, fine-tuning, agentic workflows, prompt caching…).
- **Seen-tracking**: mảng `seenSkillIds` trên Firestore `users/{uid}` → loại item đã xem. Hết unseen → "all caught up" (cycle sau).
- **Net-new (không phải "extend")**: Firestore REST client (`firebase-admin.ts` chỉ có `setUserTier`, 0 Firestore code) + firestore.rules.
- Flow per uid: đọc signals + seenSkillIds → lọc unseen candidates theo packs → **1 Gemini call** chọn 3 + viết explainer (personalize theo signals) → ghi `daily_inbox/{uid}/{date}` + append seenSkillIds.

## Related Code Files
- Create: `backend/src/skill-taxonomy.ts` (curated list per pack — seed ~10-15 item/pack)
- Create: `backend/src/firestore-client.ts` (REST get/commit cho Workers: get `users/{uid}`, commit `daily_inbox/{uid}/{date}` + update seenSkillIds)
- Create: `backend/src/daily-pipeline.ts` (orchestrate pick→explain→write per uid)
- Create: `firestore.rules` (commit vào repo — owner-only)
- Modify: `backend/src/openrouter-client.ts` (`generateDailySkills()` + `DAILY_SKILLS_SYSTEM_PROMPT`)
- Modify: `backend/src/index.ts` (route `POST /v1/daily/refresh` DƯỚI `/v1/*` auth middleware)

## Implementation Steps
1. **`skill-taxonomy.ts`**: 5 pack × ~10-15 skill item (`id`, `title`, `keyword`, `seedNote` 1 dòng). Curated tay (one-time); mở rộng sau.
2. **Firestore REST client** (`firestore-client.ts`): reuse token-mint (scope `firebase` đã có `firebase-admin.ts:38`); `getDoc users/{uid}`, `commitDoc daily_inbox/{uid}/{date}`, array-union `seenSkillIds`.
3. **`firestore.rules`** + commit: `match /users/{uid} { allow read,write: if request.auth.uid==uid }`; `match /daily_inbox/{uid}/{date} { allow read: if request.auth.uid==uid; allow write: if false }` (write = admin SDK). Deploy = hard gate trước device test P4.
4. **`DAILY_SKILLS_SYSTEM_PROMPT`** + `generateDailySkills()`: input packs + role/level/goal + N unseen candidates → chọn 3 phù hợp nhất + mỗi cái `{ title, keyword, whyNow (1-2 câu), coreConcept (2-3 câu), suggestedSearch }`. JSON strict.
5. **`POST /v1/daily/refresh`**: DƯỚI auth middleware; `uid = c.get('user').uid` (KHÔNG body). Server-side quota `peekUsage`/`commitUsage` bucket `usage:{uid}:refresh:{date}` (free 1 / pro 3) + circuit-breaker `gemini:global:{date}` TRƯỚC Gemini. Gọi pipeline, return 3 items.
6. **Fallback**: unseen rỗng → "all caught up" (return []); Gemini fail → return candidates với seedNote (chưa explainer) + retry; circuit-breaker hit → cached/seed.
7. Deploy preview, test refresh 1 uid thật + cross-uid/unauth → 401/403.

## Success Criteria
- [ ] `POST /v1/daily/refresh` (authenticated) trả 3 skill item + explainer, ghi `daily_inbox/{uid}/{date}`, append seenSkillIds; cross-uid/unauth → 401/403
- [ ] Item phản ánh packs (+ signals nếu có); không lặp item đã xem; hết → "all caught up"
- [ ] `firestore.rules` committed + deployed (owner-only)
- [ ] Server quota gate + circuit-breaker chặn cost-DoS
- [ ] KHÔNG còn Reddit code/secret; deploy wrangler OK; tsc clean

## Risk Assessment
- **[Crit] Firestore REST + rules = net-new** → ưu tiên trước; reuse token-mint.
- **[Crit] Auth/route**: `/v1/` prefix + uid từ token (admin SDK bypass rules → cross-user nếu sai).
- **AI-slop**: explainer phải bám taxonomy item (keyword/seedNote là anchor) — prompt ground chặt, không bịa.
- **Content maintenance**: taxonomy tay → effort soạn seed (~50-75 item). One-time, không API. Đây là dependency MỚI thay cho Reddit creds (nhẹ hơn, tự kiểm soát).
- Seen-list phình → array-union ok tới hàng trăm; cycle/reset khi cạn.
- Cron defer: nếu sau cần pre-warm → thêm `scheduled()` + `[[triggers.crons]]` + `lastActiveAt` (ghi rõ cho v.sau).

## External deps (nhẹ hơn Reddit)
- ✅ KHÔNG cần Reddit creds nữa.
- Vẫn cần: deploy `firestore.rules` (`firebase deploy --only firestore:rules` hoặc Console) + `wrangler deploy`. Firebase service account JSON đã là secret sẵn.
