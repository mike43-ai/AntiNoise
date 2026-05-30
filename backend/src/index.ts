import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { verifyFirebaseIdToken, type FirebaseUser } from './firebase-token-verifier';
import { verifyAppCheckToken } from './app-check-verifier';
import { peekUsage, commitUsage, type Tier, type RateLimitResult } from './rate-limiter';
import {
  callAI,
  FEYNMAN_SYSTEM_PROMPT,
  FLASHCARDS_SYSTEM_PROMPT,
  LEARN_OUTLINE_SYSTEM_PROMPT,
  LEARN_DAY_EXPAND_SYSTEM_PROMPT,
} from './openrouter-client';
import { handleRevenueCatWebhook } from './revenuecat-webhook';
import { runDailyRefresh } from './daily-pipeline';

interface Env {
  OPENROUTER_API_KEY: string;
  OPENROUTER_MODEL: string;
  OPENROUTER_REFERER?: string;
  FIREBASE_PROJECT_ID: string;
  // Numeric GCP project number — App Check token issuer/audience. Non-secret.
  FIREBASE_PROJECT_NUMBER: string;
  // "true" rejects requests with a missing/invalid App Check token. Any other
  // value (default) runs in monitor mode: verify-and-log only, never block —
  // safe to ship before every client sends a token. Flip to "true" once logs
  // show ~all traffic carries a valid token.
  APP_CHECK_ENFORCE?: string;
  FIREBASE_SERVICE_ACCOUNT_JSON: string;
  REVENUECAT_WEBHOOK_AUTH: string;
  FREE_MONTHLY_LIMIT: string;
  PRO_DAILY_LIMIT: string;
  RATE_LIMIT: KVNamespace;
}

interface Variables {
  user: FirebaseUser;
  tier: Tier;
}

const app = new Hono<{ Bindings: Env; Variables: Variables }>();

app.use('*', cors({ origin: '*', allowMethods: ['POST', 'GET', 'OPTIONS'] }));

app.get('/', (c) => c.json({ name: 'anti-noise-api', ok: true }));

app.get('/health', (c) => c.json({ ok: true, ts: Date.now() }));

// RevenueCat webhook — mounted BEFORE the /v1/* auth middleware because RC
// authenticates with a static shared secret, not a Firebase ID token.
app.post('/v1/webhooks/revenuecat', async (c) => {
  return handleRevenueCatWebhook(c.req.raw, {
    REVENUECAT_WEBHOOK_AUTH: c.env.REVENUECAT_WEBHOOK_AUTH,
    FIREBASE_SERVICE_ACCOUNT_JSON: c.env.FIREBASE_SERVICE_ACCOUNT_JSON,
  });
});

// App Check — proves the request comes from an authentic build of the app, not a
// script. Gated by APP_CHECK_ENFORCE so it can ship in monitor mode (log only)
// while older clients that don't yet send a token are still in the wild, then be
// flipped to hard-reject without a redeploy of the verification path.
async function checkAppCheck(c: {
  req: { header: (n: string) => string | undefined };
  env: Env;
}): Promise<Response | null> {
  const enforce = c.env.APP_CHECK_ENFORCE === 'true';
  const token = c.req.header('x-firebase-appcheck');

  if (!token) {
    console.log('appcheck.missing', { enforce });
    return enforce
      ? Response.json({ error: 'appcheck-missing' }, { status: 401 })
      : null;
  }

  try {
    const { appId } = await verifyAppCheckToken(token, c.env.FIREBASE_PROJECT_NUMBER);
    console.log('appcheck.ok', { appId });
    return null;
  } catch (err) {
    const detail = err instanceof Error ? err.message : 'appcheck-failed';
    console.log('appcheck.fail', { detail, enforce });
    return enforce
      ? Response.json({ error: 'appcheck-invalid', detail }, { status: 401 })
      : null;
  }
}

// Auth middleware — verifies App Check (app integrity) then Firebase ID token
// (user identity) and reads tier claim.
app.use('/v1/*', async (c, next) => {
  const appCheckReject = await checkAppCheck(c);
  if (appCheckReject) return appCheckReject;

  const auth = c.req.header('authorization');
  if (!auth?.startsWith('Bearer ')) {
    return c.json({ error: 'auth-missing' }, 401);
  }

  const token = auth.slice('Bearer '.length).trim();

  try {
    const user = await verifyFirebaseIdToken(token, c.env.FIREBASE_PROJECT_ID);
    c.set('user', user);
    // Tier source-of-truth: server-signed Firebase custom claim, populated by
    // the RC → Firebase webhook bridge (POST /v1/webhooks/revenuecat). The
    // client-attached x-an-tier header is kept as a transitional fallback for
    // older builds that haven't refreshed their ID token yet — once everyone
    // is on a build that force-refreshes after a purchase event, the header
    // path can go away (target removal: v1.0.2 or first build past 2026-06-15).
    if (user.tier) {
      c.set('tier', user.tier);
    } else {
      const claimed = c.req.header('x-an-tier');
      c.set('tier', claimed === 'pro' ? 'pro' : 'free');
    }
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'auth-failed';
    console.log('auth.fail', { detail: msg });
    return c.json({ error: 'auth-invalid', detail: msg }, 401);
  }
  await next();
  return;
});

interface AIRequest {
  text?: string;
  sourceUrl?: string;
  // Base64 data URI for image captures. iOS encodes via ImageEncoder
  // (JPEG, ≤1024px long edge, q=0.80 → typically <500KB raw / <700KB base64).
  imageDataUri?: string;
}

// 6MB cap on base64 payload. Cloudflare Worker request body limit is 100MB but
// vision-capable upstreams reject larger images, and our encoder downscales to
// ≤1024px so any legitimate payload sits well under this cap.
const MAX_IMAGE_DATA_URI_BYTES = 6_000_000;

function rateLimitHeaders(r: RateLimitResult): Record<string, string> {
  return {
    'x-rate-limit': String(r.limit),
    'x-rate-remaining': String(r.remaining),
    'x-rate-reset': String(r.resetAt),
  };
}

// Reduce upstream/parse failures to a small set of user-safe keys. iOS maps each
// key to a localized message and decides whether to offer "Try again". Raw error
// text stays in worker logs (see console.error above) — never sent to client.
function classifyAIError(raw: string): 'rate-limited' | 'provider-down' | 'parse-failed' | 'empty-response' | 'unknown' {
  const m = raw.toLowerCase();
  if (m.includes('429') || m.includes('rate')) return 'rate-limited';
  if (m.includes('empty-response')) return 'empty-response';
  if (m.includes('parse') || m.includes('json') || m.includes('cards-empty')) return 'parse-failed';
  if (/\b5\d\d\b/.test(m) || m.includes('blocked')) return 'provider-down';
  return 'unknown';
}

app.post('/v1/ai/summarize', async (c) => {
  const body = (await c.req.json().catch(() => null)) as AIRequest | null;
  const hasText = !!body?.text && body.text.trim().length > 0;
  const hasImage = !!body?.imageDataUri && body.imageDataUri.length > 0;
  if (!hasText && !hasImage) {
    return c.json({ error: 'content-required' }, 400);
  }
  if (hasText && body!.text!.length > 60_000) {
    return c.json({ error: 'text-too-long', limit: 60_000 }, 413);
  }
  if (hasImage && body!.imageDataUri!.length > MAX_IMAGE_DATA_URI_BYTES) {
    return c.json({ error: 'image-too-large', limit: MAX_IMAGE_DATA_URI_BYTES }, 413);
  }

  const user = c.get('user');
  const tier = c.get('tier');
  const limits = {
    freeMonthlyLimit: parseInt(c.env.FREE_MONTHLY_LIMIT, 10),
    proDailyLimit: parseInt(c.env.PRO_DAILY_LIMIT, 10),
  };

  // Gate on usage WITHOUT consuming a slot — a slot is only committed after the
  // AI call fully succeeds, so a failed upstream call never burns the user's
  // monthly quota (otherwise N failed attempts lock out a paying-attention user).
  const rl = await peekUsage(c.env.RATE_LIMIT, user.uid, tier, limits);

  for (const [k, v] of Object.entries(rateLimitHeaders(rl))) c.header(k, v);

  if (!rl.allowed) {
    return c.json({ error: 'rate-limit-exceeded', tier, resetAt: rl.resetAt }, 429);
  }

  const sourceLine = body!.sourceUrl ? `Source: ${body!.sourceUrl}\n\n` : '';
  const userPrompt = hasText
    ? `${sourceLine}Content:\n${body!.text}`
    : `${sourceLine}Content: read the visible content of the attached image and apply the Feynman shape.`;

  try {
    const { text, resolvedModel } = await callAI({
      apiKey: c.env.OPENROUTER_API_KEY,
      model: c.env.OPENROUTER_MODEL,
      systemInstruction: FEYNMAN_SYSTEM_PROMPT,
      userPrompt,
      imageDataUri: hasImage ? body!.imageDataUri : undefined,
      jsonResponse: true,
      temperature: 0.4,
      referer: c.env.OPENROUTER_REFERER,
      title: 'Anti Noise',
    });
    const payload = JSON.parse(text) as Record<string, unknown>;
    await commitUsage(c.env.RATE_LIMIT, user.uid, tier, limits);
    return c.json({ payload, model: resolvedModel });
  } catch (err) {
    const raw = err instanceof Error ? err.message : 'ai-failed';
    console.error('summarize.failed', { uid: user.uid, raw });
    return c.json({ error: 'ai-unavailable', detail: classifyAIError(raw) }, 502);
  }
});

interface Flashcard {
  question: string;
  answer: string;
  hint?: string | null;
  difficulty: number;
  layer?: number; // Bloom layer 0-2 (v1.1 layered decks); absent → flat (0)
}

// Normalize a model's raw card array: clamp layer to 0-2 (default 0) so a missing
// or garbage layer never breaks iOS ordering, and cap at 15 (the layered ceiling).
// Throws when the array is empty so the caller surfaces a retry instead of an empty deck.
export function normalizeCards(rawCards: unknown): Flashcard[] {
  if (!Array.isArray(rawCards) || rawCards.length === 0) {
    throw new Error('cards-empty');
  }
  return (rawCards as Flashcard[]).slice(0, 15).map((card) => ({
    ...card,
    layer: Math.min(2, Math.max(0, Math.round(Number(card.layer ?? 0)) || 0)),
  }));
}

app.post('/v1/ai/flashcards', async (c) => {
  const body = (await c.req.json().catch(() => null)) as AIRequest | null;
  if (!body?.text || body.text.trim().length === 0) {
    return c.json({ error: 'text-required' }, 400);
  }
  if (body.text.length > 60_000) {
    return c.json({ error: 'text-too-long', limit: 60_000 }, 413);
  }

  const user = c.get('user');
  const tier = c.get('tier');
  const limits = {
    freeMonthlyLimit: parseInt(c.env.FREE_MONTHLY_LIMIT, 10),
    proDailyLimit: parseInt(c.env.PRO_DAILY_LIMIT, 10),
  };

  const rl = await peekUsage(c.env.RATE_LIMIT, user.uid, tier, limits);

  for (const [k, v] of Object.entries(rateLimitHeaders(rl))) c.header(k, v);

  if (!rl.allowed) {
    return c.json({ error: 'rate-limit-exceeded', tier, resetAt: rl.resetAt }, 429);
  }

  try {
    const { text, resolvedModel } = await callAI({
      apiKey: c.env.OPENROUTER_API_KEY,
      model: c.env.OPENROUTER_MODEL,
      systemInstruction: FLASHCARDS_SYSTEM_PROMPT,
      userPrompt: body.text,
      jsonResponse: true,
      temperature: 0.5,
      referer: c.env.OPENROUTER_REFERER,
      title: 'Anti Noise',
    });

    const parsed = JSON.parse(text) as { cards?: Flashcard[] };
    const cards = normalizeCards(parsed.cards);

    await commitUsage(c.env.RATE_LIMIT, user.uid, tier, limits);
    return c.json({ cards, model: resolvedModel });
  } catch (err) {
    const raw = err instanceof Error ? err.message : 'ai-failed';
    console.error('flashcards.failed', { uid: user.uid, raw });
    return c.json({ error: 'ai-unavailable', detail: classifyAIError(raw) }, 502);
  }
});

// Daily Knowledge refresh — picks 3 unseen skills for the user's topic packs and
// writes them to daily_inbox. Under /v1/* so auth is enforced; uid comes from the
// verified token (never the body) so a caller can't refresh/poison another user.
app.post('/v1/daily/refresh', async (c) => {
  const user = c.get('user');
  const tier = c.get('tier');
  const limits = {
    freeMonthlyLimit: parseInt(c.env.FREE_MONTHLY_LIMIT, 10),
    proDailyLimit: parseInt(c.env.PRO_DAILY_LIMIT, 10),
  };

  // Server-side gate BEFORE any Gemini call (prevents cost-DoS). Reuses the
  // shared AI quota bucket; the finer per-feature "1 article/day" cap is enforced
  // client-side for now (a dedicated server bucket can be added later).
  const rl = await peekUsage(c.env.RATE_LIMIT, user.uid, tier, limits);
  for (const [k, v] of Object.entries(rateLimitHeaders(rl))) c.header(k, v);
  if (!rl.allowed) {
    return c.json({ error: 'rate-limit-exceeded', tier, resetAt: rl.resetAt }, 429);
  }

  try {
    const result = await runDailyRefresh(
      {
        OPENROUTER_API_KEY: c.env.OPENROUTER_API_KEY,
        OPENROUTER_MODEL: c.env.OPENROUTER_MODEL,
        OPENROUTER_REFERER: c.env.OPENROUTER_REFERER,
        FIREBASE_SERVICE_ACCOUNT_JSON: c.env.FIREBASE_SERVICE_ACCOUNT_JSON,
      },
      user.uid,
    );
    // Only consume quota when a model call actually happened.
    if (result.status === 'ok') {
      await commitUsage(c.env.RATE_LIMIT, user.uid, tier, limits);
    }
    return c.json({ status: result.status, items: result.items });
  } catch (err) {
    const raw = err instanceof Error ? err.message : 'daily-failed';
    console.error('daily.refresh.failed', { uid: user.uid, raw });
    return c.json({ error: 'daily-unavailable', detail: classifyAIError(raw) }, 502);
  }
});

// --- Deep Learn (v1.2): Pro-only multi-day course generation ---

interface OutlineDay {
  day: number;
  subtopic: string;
  objective: string;
}

// POST /v1/learn/path — generate the 7-day outline + expand Day 1. Pro-only.
app.post('/v1/learn/path', async (c) => {
  const body = (await c.req.json().catch(() => null)) as {
    topic?: string;
    deckTitle?: string;
    captureSnippets?: string[];
    role?: string;
    level?: string;
  } | null;

  const topic = body?.topic?.trim();
  if (!topic) return c.json({ error: 'topic-required' }, 400);
  if (topic.length > 200) return c.json({ error: 'topic-too-long', limit: 200 }, 413);

  const user = c.get('user');
  const tier = c.get('tier');
  if (tier !== 'pro') return c.json({ error: 'pro-required' }, 403);

  const limits = {
    freeMonthlyLimit: parseInt(c.env.FREE_MONTHLY_LIMIT, 10),
    proDailyLimit: parseInt(c.env.PRO_DAILY_LIMIT, 10),
  };
  const rl = await peekUsage(c.env.RATE_LIMIT, user.uid, tier, limits);
  for (const [k, v] of Object.entries(rateLimitHeaders(rl))) c.header(k, v);
  if (!rl.allowed) return c.json({ error: 'rate-limit-exceeded', tier, resetAt: rl.resetAt }, 429);

  // Cap snippet payload so a huge capture set can't blow up the prompt/cost.
  const snippets = (body?.captureSnippets ?? []).slice(0, 8).map((s) => String(s).slice(0, 1000));

  try {
    const outlinePrompt = JSON.stringify({
      topic,
      deckTitle: body?.deckTitle ?? null,
      user: { role: body?.role ?? null, level: body?.level ?? null },
      snippets,
    });
    const outlineRes = await callAI({
      apiKey: c.env.OPENROUTER_API_KEY,
      model: c.env.OPENROUTER_MODEL,
      systemInstruction: LEARN_OUTLINE_SYSTEM_PROMPT,
      userPrompt: outlinePrompt,
      jsonResponse: true,
      temperature: 0.5,
      referer: c.env.OPENROUTER_REFERER,
      title: 'Anti Noise',
    });
    const outline = JSON.parse(outlineRes.text) as { days?: OutlineDay[] };
    const days = Array.isArray(outline.days) ? outline.days : [];
    if (days.length === 0) throw new Error('outline-empty');

    const day1Meta = days.find((d) => d.day === 1) ?? days[0];
    const day1 = await expandDay(c, {
      topic,
      dayIndex: 1,
      subtopic: day1Meta.subtopic,
      objective: day1Meta.objective,
      priorSubtopics: [],
    });

    await commitUsage(c.env.RATE_LIMIT, user.uid, tier, limits);
    return c.json({ outlineJSON: JSON.stringify({ days }), day1, model: outlineRes.resolvedModel });
  } catch (err) {
    const raw = err instanceof Error ? err.message : 'learn-failed';
    console.error('learn.path.failed', { uid: user.uid, raw });
    return c.json({ error: 'ai-unavailable', detail: classifyAIError(raw) }, 502);
  }
});

// POST /v1/learn/day — lazily expand one later day of an active course. Pro-only.
app.post('/v1/learn/day', async (c) => {
  const body = (await c.req.json().catch(() => null)) as {
    topic?: string;
    dayIndex?: number;
    subtopic?: string;
    objective?: string;
    priorSubtopics?: string[];
  } | null;

  const topic = body?.topic?.trim();
  const subtopic = body?.subtopic?.trim();
  if (!topic || !subtopic || typeof body?.dayIndex !== 'number') {
    return c.json({ error: 'invalid-body' }, 400);
  }

  const user = c.get('user');
  const tier = c.get('tier');
  if (tier !== 'pro') return c.json({ error: 'pro-required' }, 403);

  const limits = {
    freeMonthlyLimit: parseInt(c.env.FREE_MONTHLY_LIMIT, 10),
    proDailyLimit: parseInt(c.env.PRO_DAILY_LIMIT, 10),
  };
  const rl = await peekUsage(c.env.RATE_LIMIT, user.uid, tier, limits);
  for (const [k, v] of Object.entries(rateLimitHeaders(rl))) c.header(k, v);
  if (!rl.allowed) return c.json({ error: 'rate-limit-exceeded', tier, resetAt: rl.resetAt }, 429);

  try {
    const day = await expandDay(c, {
      topic,
      dayIndex: body.dayIndex,
      subtopic,
      objective: body?.objective ?? '',
      priorSubtopics: (body?.priorSubtopics ?? []).slice(0, 12).map((s) => String(s).slice(0, 120)),
    });
    await commitUsage(c.env.RATE_LIMIT, user.uid, tier, limits);
    return c.json({ ...day, model: 'ok' });
  } catch (err) {
    const raw = err instanceof Error ? err.message : 'learn-failed';
    console.error('learn.day.failed', { uid: user.uid, raw });
    return c.json({ error: 'ai-unavailable', detail: classifyAIError(raw) }, 502);
  }
});

// Expand one day → {concept, cards, applyPrompt}. Shared by both learn endpoints.
async function expandDay(
  c: { env: Env },
  args: { topic: string; dayIndex: number; subtopic: string; objective: string; priorSubtopics: string[] },
): Promise<{ concept: string; cards: Flashcard[]; applyPrompt: string }> {
  const { text } = await callAI({
    apiKey: c.env.OPENROUTER_API_KEY,
    model: c.env.OPENROUTER_MODEL,
    systemInstruction: LEARN_DAY_EXPAND_SYSTEM_PROMPT,
    userPrompt: JSON.stringify(args),
    jsonResponse: true,
    temperature: 0.5,
    referer: c.env.OPENROUTER_REFERER,
    title: 'Anti Noise',
  });
  const parsed = JSON.parse(text) as { concept?: string; cards?: unknown; applyPrompt?: string };
  const concept = (parsed.concept ?? '').trim();
  if (!concept) throw new Error('concept-empty');
  return {
    concept,
    cards: normalizeCards(parsed.cards),
    applyPrompt: (parsed.applyPrompt ?? '').trim(),
  };
}

app.notFound((c) => c.json({ error: 'not-found' }, 404));

app.onError((err, c) => {
  console.error('unhandled', err);
  return c.json({ error: 'internal' }, 500);
});

export default app;
