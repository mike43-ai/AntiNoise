import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { verifyFirebaseIdToken, type FirebaseUser } from './firebase-token-verifier';
import { checkAndIncrement, type Tier, type RateLimitResult } from './rate-limiter';
import {
  callGemini,
  FEYNMAN_SYSTEM_PROMPT,
  FLASHCARDS_SYSTEM_PROMPT,
} from './gemini-client';

interface Env {
  GEMINI_API_KEY: string;
  GEMINI_MODEL: string;
  FIREBASE_PROJECT_ID: string;
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
    // Tier comes from client-attached header (verified later against RC webhook).
    // For now: default to free, allow client to claim 'pro' — we will harden
    // by reading a custom Firebase claim populated by an RC webhook in v1.0.2.
    const claimed = c.req.header('x-an-tier');
    c.set('tier', claimed === 'pro' ? 'pro' : 'free');
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'auth-failed';
    return c.json({ error: 'auth-invalid', detail: msg }, 401);
  }
  await next();
  return;
});

interface AIRequest {
  text?: string;
  sourceUrl?: string;
}

function rateLimitHeaders(r: RateLimitResult): Record<string, string> {
  return {
    'x-rate-limit': String(r.limit),
    'x-rate-remaining': String(r.remaining),
    'x-rate-reset': String(r.resetAt),
  };
}

app.post('/v1/ai/summarize', async (c) => {
  const body = (await c.req.json().catch(() => null)) as AIRequest | null;
  if (!body?.text || body.text.trim().length === 0) {
    return c.json({ error: 'text-required' }, 400);
  }
  if (body.text.length > 60_000) {
    return c.json({ error: 'text-too-long', limit: 60_000 }, 413);
  }

  const user = c.get('user');
  const tier = c.get('tier');

  const rl = await checkAndIncrement(c.env.RATE_LIMIT, user.uid, tier, {
    freeMonthlyLimit: parseInt(c.env.FREE_MONTHLY_LIMIT, 10),
    proDailyLimit: parseInt(c.env.PRO_DAILY_LIMIT, 10),
  });

  for (const [k, v] of Object.entries(rateLimitHeaders(rl))) c.header(k, v);

  if (!rl.allowed) {
    return c.json({ error: 'rate-limit-exceeded', tier, resetAt: rl.resetAt }, 429);
  }

  const userPrompt =
    (body.sourceUrl ? `Source: ${body.sourceUrl}\n\n` : '') +
    `Content:\n${body.text}`;

  try {
    const summary = await callGemini({
      apiKey: c.env.GEMINI_API_KEY,
      model: c.env.GEMINI_MODEL,
      systemInstruction: FEYNMAN_SYSTEM_PROMPT,
      userPrompt,
      responseMimeType: 'text/plain',
    });
    return c.json({ summary, model: c.env.GEMINI_MODEL });
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'gemini-failed';
    return c.json({ error: 'ai-unavailable', detail: msg }, 502);
  }
});

interface Flashcard {
  front: string;
  back: string;
  type: 'recognize' | 'recall' | 'apply';
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

  const rl = await checkAndIncrement(c.env.RATE_LIMIT, user.uid, tier, {
    freeMonthlyLimit: parseInt(c.env.FREE_MONTHLY_LIMIT, 10),
    proDailyLimit: parseInt(c.env.PRO_DAILY_LIMIT, 10),
  });

  for (const [k, v] of Object.entries(rateLimitHeaders(rl))) c.header(k, v);

  if (!rl.allowed) {
    return c.json({ error: 'rate-limit-exceeded', tier, resetAt: rl.resetAt }, 429);
  }

  try {
    const raw = await callGemini({
      apiKey: c.env.GEMINI_API_KEY,
      model: c.env.GEMINI_MODEL,
      systemInstruction: FLASHCARDS_SYSTEM_PROMPT,
      userPrompt: body.text,
      responseMimeType: 'application/json',
      temperature: 0.5,
    });

    const cards = JSON.parse(raw) as Flashcard[];
    if (!Array.isArray(cards) || cards.length === 0) {
      throw new Error('cards-empty');
    }

    return c.json({ cards, model: c.env.GEMINI_MODEL });
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'gemini-failed';
    return c.json({ error: 'ai-unavailable', detail: msg }, 502);
  }
});

app.notFound((c) => c.json({ error: 'not-found' }, 404));

app.onError((err, c) => {
  console.error('unhandled', err);
  return c.json({ error: 'internal' }, 500);
});

export default app;
