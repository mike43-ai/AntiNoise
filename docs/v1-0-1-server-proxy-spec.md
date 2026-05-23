# Anti Noise v1.0.1 — Server Proxy + Gemini Migration

> **Theme**: Kill BYOK, switch AI vendor GPT-4o → Gemini 2.0 Flash.
> **Effort**: 3-5 ngày dev + ASC re-review.
> **Status**: Scoped, awaiting v1.0 approval before kickoff.

## Decision history

- 2026-05-18: User decided to kill BYOK (Profile → API Key) after MVP. UX win = lower onboarding friction.
- 2026-05-23: Switch GPT-4o → Gemini 2.0 Flash (unlocks plan rule §2). Reason: vendor consolidation, VI quality, free tier, native multimodal, cheaper than alternatives (Kimi, GPT-4o-mini).

## Backend (new)

**Host**: Cloudflare Workers
- Low latency
- Free 100K req/day (covers MVP scale)
- Fits cron jobs for v1.1 articles feature

**Endpoints**:
- `POST /v1/ai/summarize`
- `POST /v1/ai/flashcards`

**Auth**: Verify Firebase ID token via Firebase Admin SDK.

**Rate limiting**:
- Per Firebase UID
- Per subscription tier:
  - Free: 5 summaries/month
  - Pro: unlimited (but cap abuse ~200/day)

**Quota**: Read from Firestore `usage` collection or recompute server-side.

**Secrets**: Gemini API key as Cloudflare Workers secret. Never in client.

**Monitoring**: Gemini dashboard + alarm if monthly spend > threshold.

## Client refactor

- Delete `Profile → API Key` UI
- Delete `SecretStore` OpenAI key handling
- Rename `OpenAIClient.swift` → `AIClient.swift`
- Call backend with Firebase ID token in `Authorization: Bearer <token>` header
- Remove anonymous fallback path (now requires sign-in for AI)
- Error UX: "AI temporarily unavailable" thay vì "Check your API key"
- Silently delete existing Keychain OpenAI key on upgrade

## Model swap

- GPT-4o → Gemini 2.0 Flash
- Same prompts (retest output quality before release)
- Vision flow: GPT-4o vision → Gemini native multimodal (single endpoint)

## Pricing & cost

| Metric | Value |
|---|---|
| Infra cost / 1000 active users | ~$25/mo |
| Pro $9.99 × 5% conversion / 1000 users | $500/mo |
| Gross margin | 95% |

Hard cap heavy-user abuse: 200 captures/day max kể cả Pro.

Monitor first month cho cost outliers.

## Risks

- ASC re-review trigger lại issue cũ/mới
- Gemini Flash quality khác GPT-4o → test trước release
- Cloudflare Workers cold start 200-500ms (acceptable)
- Abuse: scripted client với stolen Firebase token → rate limit per IP + UID
- Backend uptime → captures fail when down. Add fallback message + queue retry.

## Migration

Existing v1.0 users có OpenAI key trong Keychain. v1.0.1 upgrade:
- Silently delete from Keychain
- Force backend use only
- Simpler maintenance (không giữ BYOK fallback)

## Cross-references

- [Product roadmap](product-roadmap.md)
- [v1.1 daily knowledge spec](v1-1-daily-knowledge-spec.md)
- [Growth playbook](growth-playbook.md)
