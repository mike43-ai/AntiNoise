# Anti Noise API

Server proxy for Anti Noise v1.0.1 — replaces the in-app BYOK flow with a Firebase-auth'd, model-swappable AI backend on Cloudflare Workers.

## Stack

- **Runtime:** Cloudflare Workers
- **Framework:** Hono (TypeScript)
- **Auth:** Firebase ID token (RS256, verified via Google public keys — no Firebase Admin SDK because it requires Node APIs unavailable on Workers)
- **AI:** OpenRouter chat completions (default: `google/gemini-2.0-flash-001`; swap any OpenRouter model id without code change)
- **Rate limit:** Workers KV per-UID counters (free: 5/month, pro: 200/day)

## Endpoints

| Method | Path | Body | Returns |
|---|---|---|---|
| POST | `/v1/ai/summarize` | `{ text, sourceUrl? }` | `{ summary, model }` |
| POST | `/v1/ai/flashcards` | `{ text, sourceUrl? }` | `{ cards: [{ front, back, type }], model }` |
| GET | `/health` | — | `{ ok, ts }` |

All `/v1/*` requests require:
- `Authorization: Bearer <firebase-id-token>`
- Optional `x-an-tier: pro` (client-claimed; will be hardened against RC webhook in v1.0.2)

Rate-limit headers on every response:
- `x-rate-limit`, `x-rate-remaining`, `x-rate-reset` (unix ms)

429 returned when bucket is exhausted.

## Setup (first time)

```bash
cd backend
npm install

# 1. Authenticate with Cloudflare (opens browser)
npx wrangler login

# 2. Create KV namespace for rate-limit counters
npx wrangler kv namespace create RATE_LIMIT
# → copy the returned id into wrangler.toml under [[kv_namespaces]]

# 3. Set production OpenRouter key
npx wrangler secret put OPENROUTER_API_KEY
# → paste your key from https://openrouter.ai/keys

# 4. (Local dev) Copy secret template
cp .dev.vars.example .dev.vars
# → edit OPENROUTER_API_KEY for local-only use
```

## Run locally

```bash
npm run dev
# Worker on http://localhost:8787
```

Smoke test:

```bash
curl http://localhost:8787/health
```

Authenticated call (replace `<TOKEN>` with a real Firebase ID token from the iOS app — paste from Xcode console after sign-in):

```bash
curl -X POST http://localhost:8787/v1/ai/summarize \
  -H "Authorization: Bearer <TOKEN>" \
  -H "content-type: application/json" \
  -d '{"text": "Article body here..."}'
```

## Deploy

```bash
npm run deploy
# Worker live at https://anti-noise-api.<account>.workers.dev
```

To attach a custom domain (`api.antinoise.app`):
1. Add the zone in Cloudflare dashboard
2. Uncomment the `routes` block in `wrangler.toml`
3. `npm run deploy`

## Logs

```bash
npm run tail
# Live tail of production worker
```

## Cost monitoring

- **Cloudflare free tier:** 100K req/day Worker + 100K read + 1K write KV/day
- **OpenRouter:** pass-through provider pricing + ~5% margin. For default `google/gemini-2.0-flash-001`: ~$0.10/M input, ~$0.40/M output tokens.
- Estimate at 1000 active users: ~$25–30/mo total infra (workers free, OpenRouter paid)
- Watch [Cloudflare dashboard](https://dash.cloudflare.com) and [OpenRouter activity](https://openrouter.ai/activity)

## Swapping models

The active model is `OPENROUTER_MODEL` in `wrangler.toml`. To swap providers:

1. Pick a model id from https://openrouter.ai/models
2. Edit `OPENROUTER_MODEL` in `wrangler.toml`
3. `npm run deploy`

No code changes — prompts are model-agnostic (instruct strict JSON output via system instruction). Tested model ids: `google/gemini-2.0-flash-001`, `anthropic/claude-haiku-4-5`, `openai/gpt-4o-mini`.

## Hardening checklist (before v1.0.1 ASC submit)

- [ ] Replace client-claimed `x-an-tier` header with a Firebase custom claim populated by an RC webhook (`POST /v1/webhooks/revenuecat`)
- [ ] Add per-IP rate limit on top of per-UID (Cloudflare Turnstile or Workers IP)
- [ ] Add cost alarm: if monthly Gemini spend > $X, route to a free-tier-only fallback or hard-stop
- [ ] Pen-test: forged token, replayed token, expired token, kid-rotation
- [ ] Log Gemini latency to find p99; if > 4s, add a "Generating…" UX in client
