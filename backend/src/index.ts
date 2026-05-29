import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { verifyFirebaseIdToken, type FirebaseUser } from './firebase-token-verifier';
import { peekUsage, commitUsage, type Tier, type RateLimitResult } from './rate-limiter';
import {
  callAI,
  FEYNMAN_SYSTEM_PROMPT,
  FLASHCARDS_SYSTEM_PROMPT,
} from './openrouter-client';
import { handleRevenueCatWebhook } from './revenuecat-webhook';

interface Env {
  OPENROUTER_API_KEY: string;
  OPENROUTER_MODEL: string;
  OPENROUTER_REFERER?: string;
  FIREBASE_PROJECT_ID: string;
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

// Auth middleware — verifies Firebase ID token and reads tier claim.
app.use('/v1/*', async (c, next) => {
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
    const rawCards = parsed.cards;
    if (!Array.isArray(rawCards) || rawCards.length === 0) {
      throw new Error('cards-empty');
    }
    // Normalize layer to 0-2 (default 0) so a missing/garbage layer never breaks
    // iOS ordering; cap at 15 (the layered ceiling).
    const cards = rawCards.slice(0, 15).map((card) => ({
      ...card,
      layer: Math.min(2, Math.max(0, Math.round(Number(card.layer ?? 0)) || 0)),
    }));

    await commitUsage(c.env.RATE_LIMIT, user.uid, tier, limits);
    return c.json({ cards, model: resolvedModel });
  } catch (err) {
    const raw = err instanceof Error ? err.message : 'ai-failed';
    console.error('flashcards.failed', { uid: user.uid, raw });
    return c.json({ error: 'ai-unavailable', detail: classifyAIError(raw) }, 502);
  }
});

app.notFound((c) => c.json({ error: 'not-found' }, 404));

app.onError((err, c) => {
  console.error('unhandled', err);
  return c.json({ error: 'internal' }, 500);
});

export default app;
