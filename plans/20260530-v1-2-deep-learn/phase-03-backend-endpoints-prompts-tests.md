# Phase 03 — Backend: /learn/path + /learn/day + prompts + tests

**Context:** `reports/scout-corrections.md` · `docs/v1-2-deep-learn-spec.md` §Backend, §B3

## Overview
- **Priority:** P1
- **Status:** pending
- **Depends:** none (parallel with 01–02). Reuses the v1.0.1 OpenRouter proxy.
- Two endpoints on the existing Hono Worker: outline+Day1 generation, and lazy single-day expansion.

## Key insights
- Reuse the exact peek/commit quota pattern from `/v1/ai/summarize` (`index.ts:180-206`): `peekUsage`
  before the Gemini call, `commitUsage` only after success → a failed gen never burns quota.
- Auth/tier come from middleware: `c.get('user')`, `c.get('tier')` (`index.ts:170-171`).
- All gen goes through `callAI` (`openrouter-client.ts:44`) with `jsonResponse:true`.
- Pro-gate is enforced **server-side too**: reject `tier !== 'pro'` before the Gemini call (client also
  gates via paywall in phase 05, but the server is the real boundary so a free token can't gen).

## Requirements
- Functional:
  - `POST /v1/learn/path` `{ deckTitle, topic, captureSnippets?: string[], role?, level? }`
    → generates 7-day outline (cheap, one call) + expands Day 1 → returns `{ path: {outlineJSON},
    day1: {concept, cards[], applyPrompt}, model }`.
  - `POST /v1/learn/day` `{ topic, dayIndex, subtopic, objective, priorSubtopics: string[] }`
    → expands one day → returns `{ concept, cards[], applyPrompt, model }`.
  - Both: auth required, `tier==='pro'` required (403 otherwise), quota peek/commit, input size caps.
- Non-functional: TS strict; reuse modules; vitest tests; no secrets in code.

## Architecture / data flow
```
client (Pro) → POST /v1/learn/path {topic, snippets, role, level}
  → verify auth+tier → peekUsage (else 429) → callAI(OUTLINE prompt) → parse 7×{day,subtopic,objective}
  → callAI(DAY_EXPAND prompt for day 1) → parse {concept, cards(layered), applyPrompt}
  → commitUsage → return {outlineJSON, day1, model}

client → POST /v1/learn/day {topic, dayIndex, subtopic, objective, priorSubtopics}
  → verify auth+tier → peekUsage → callAI(DAY_EXPAND) → commitUsage → return {concept, cards, applyPrompt}
```
Cards use the SAME shape/normalization as `/v1/ai/flashcards` (`layer` clamped 0-2, sliced to a cap).

## Related code files
**Modify:**
- `backend/src/openrouter-client.ts` — add `LEARN_OUTLINE_SYSTEM_PROMPT` and
  `LEARN_DAY_EXPAND_SYSTEM_PROMPT` (export consts, mirror existing prompt style). Outline: 7 days,
  each `{day, subtopic, objective}`, day 7 = synthesis/review, build-on-prior, ground in snippets if
  given. Expand: Feynman concept ≤150 words + 3-5 layered cards (Recognize/Recall/Apply) + 1 apply prompt.
- `backend/src/index.ts` — add `app.post('/v1/learn/path', ...)` and `app.post('/v1/learn/day', ...)`
  following the summarize/flashcards handlers. Add a shared card-normalizer (reuse the
  `rawCards.slice(0,15).map(... clamp layer ...)` logic from `index.ts:266-269` — extract to a small
  helper to honor DRY).

**Create:**
- `backend/test/learn-endpoints.test.ts` — vitest: outline parse, day-expand parse, card-layer
  normalization, 403 for free tier, 429 when quota exhausted (peek), commit only on success.

## Implementation steps
1. Add the two system prompts to `openrouter-client.ts` (JSON-shaped outputs).
2. Extract `normalizeCards()` helper (shared by `/v1/ai/flashcards` + new day endpoint).
3. Implement `/v1/learn/path`: validate body + size caps; reject non-pro (403 `{error:'pro-required'}`);
   peekUsage→429; callAI(outline)→parse→callAI(day-expand day1)→normalize cards; commitUsage; return.
4. Implement `/v1/learn/day`: validate; reject non-pro; peek; callAI(expand); normalize; commit; return.
5. Decide quota cost: **1 path call = 1 commit; 1 day call = 1 commit** (Pro daily limit applies). Note
   path does 2 Gemini calls but counts as 1 quota unit (cheap, Pro-only).
6. Write vitest tests; mock `callAI` (don't hit OpenRouter). Run `npm test` in `backend/`.

## Todo
- [ ] Two system prompts in `openrouter-client.ts`
- [ ] `normalizeCards()` helper (DRY with flashcards)
- [ ] `POST /v1/learn/path` (outline + Day 1, pro-gate, peek/commit)
- [ ] `POST /v1/learn/day` (lazy expand, pro-gate, peek/commit)
- [ ] vitest tests green
- [ ] `wrangler deploy` (deploy step gated until iOS ready)

## Success criteria
- `npm test` passes incl. new file.
- Manual `curl` (Pro token) to `/v1/learn/path` returns valid `{outlineJSON, day1{concept,cards,applyPrompt}}`.
- Free-tier token → 403; exhausted quota → 429; failed Gemini → 502 and quota NOT consumed.

## Risk assessment
| Risk | L×I | Mitigation |
|------|-----|-----------|
| Outline + Day1 in one request → latency (2 sequential Gemini calls) | M×M | Show 3-5s loading copy (phase 04). Acceptable for a one-time opt-in. Cron pre-gen deferred. |
| Model returns malformed JSON for outline | M×M | `jsonResponse:true` + try/catch → 502 `ai-unavailable`; client shows retry. |
| Content "padding"/repetition across days | M×M | Expand prompt receives `priorSubtopics` to avoid repeat; concept ≤150 words; day 7 = synthesis. |
| Server pro-gate forgotten → free users gen on Gemini | L×H | Explicit `tier==='pro'` check first line of each handler; covered by test. |

## Rollback
Additive: two new routes + two prompts + one test file. Revert removes routes; existing endpoints
untouched. No deploy until iOS calls them.

## Open questions
- Quota unit for a path (1 vs 2)? Defaulting to **1**. Flag for user.
