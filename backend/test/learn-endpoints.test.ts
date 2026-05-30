import { describe, it, expect, vi, beforeEach } from 'vitest';
import { fakeKV } from './fake-kv';

// Mock the AI client (keep the prompt consts as harmless strings) and the token
// verifier so we can drive the Deep Learn endpoints without OpenRouter/Firebase.
const callAI = vi.fn();
vi.mock('../src/openrouter-client', () => ({
  callAI: (...a: unknown[]) => callAI(...a),
  FEYNMAN_SYSTEM_PROMPT: 'F',
  FLASHCARDS_SYSTEM_PROMPT: 'FC',
  LEARN_OUTLINE_SYSTEM_PROMPT: 'OUT',
  LEARN_DAY_EXPAND_SYSTEM_PROMPT: 'DAY',
  DAILY_SKILLS_SYSTEM_PROMPT: 'DS',
}));
vi.mock('../src/firebase-token-verifier', () => ({
  verifyFirebaseIdToken: async () => ({ uid: 'u1' }), // tier comes from x-an-tier header
}));

import app, { normalizeCards } from '../src/index';

function makeEnv(kv = fakeKV()) {
  return {
    RATE_LIMIT: kv,
    FIREBASE_PROJECT_ID: 'p',
    FIREBASE_PROJECT_NUMBER: '1',
    FREE_MONTHLY_LIMIT: '10',
    PRO_DAILY_LIMIT: '100',
    OPENROUTER_API_KEY: 'k',
    OPENROUTER_MODEL: 'm',
  } as unknown as Record<string, unknown>;
}

function post(path: string, tier: string, body: unknown, env = makeEnv()) {
  return app.request(
    path,
    {
      method: 'POST',
      headers: {
        authorization: 'Bearer x',
        'x-an-tier': tier,
        'content-type': 'application/json',
      },
      body: JSON.stringify(body),
    },
    env,
  );
}

beforeEach(() => callAI.mockReset());

describe('normalizeCards', () => {
  it('clamps layer to 0-2 and defaults missing/garbage to 0', () => {
    const out = normalizeCards([
      { question: 'a', answer: 'a', difficulty: 1, layer: 5 },
      { question: 'b', answer: 'b', difficulty: 1 },
      { question: 'c', answer: 'c', difficulty: 1, layer: -3 },
      { question: 'd', answer: 'd', difficulty: 1, layer: 2 },
    ]);
    expect(out.map((c) => c.layer)).toEqual([2, 0, 0, 2]);
  });

  it('caps at 15 cards', () => {
    const many = Array.from({ length: 30 }, (_, i) => ({ question: `q${i}`, answer: 'a', difficulty: 1 }));
    expect(normalizeCards(many).length).toBe(15);
  });

  it('throws on an empty / non-array input', () => {
    expect(() => normalizeCards([])).toThrow();
    expect(() => normalizeCards(undefined)).toThrow();
  });
});

describe('POST /v1/learn/path', () => {
  it('rejects a free-tier user with 403 before any AI call', async () => {
    const res = await post('/v1/learn/path', 'free', { topic: 'RAG' });
    expect(res.status).toBe(403);
    expect(callAI).not.toHaveBeenCalled();
  });

  it('400 when topic is missing', async () => {
    const res = await post('/v1/learn/path', 'pro', {});
    expect(res.status).toBe(400);
  });

  it('generates outline + day 1 for a Pro user and commits one quota slot', async () => {
    callAI
      .mockResolvedValueOnce({
        text: JSON.stringify({
          days: Array.from({ length: 7 }, (_, i) => ({ day: i + 1, subtopic: `s${i + 1}`, objective: `o${i + 1}` })),
        }),
        resolvedModel: 'gem',
      })
      .mockResolvedValueOnce({
        text: JSON.stringify({
          concept: 'Day one concept.',
          cards: [{ question: 'q', answer: 'a', difficulty: 2, layer: 1 }],
          applyPrompt: 'Try it.',
        }),
        resolvedModel: 'gem',
      });

    const kv = fakeKV();
    const res = await post('/v1/learn/path', 'pro', { topic: 'RAG' }, makeEnv(kv));
    expect(res.status).toBe(200);
    const json = (await res.json()) as { outlineJSON: string; day1: { concept: string; cards: unknown[] } };
    expect(JSON.parse(json.outlineJSON).days).toHaveLength(7);
    expect(json.day1.concept).toBe('Day one concept.');
    expect(json.day1.cards).toHaveLength(1);
    expect(callAI).toHaveBeenCalledTimes(2); // outline + day1
    // one slot committed (pro day bucket)
    expect([...kv.store.values()][0]).toBe('1');
  });

  it('does NOT commit quota when the outline call fails', async () => {
    callAI.mockRejectedValueOnce(new Error('provider-down'));
    const kv = fakeKV();
    const res = await post('/v1/learn/path', 'pro', { topic: 'RAG' }, makeEnv(kv));
    expect(res.status).toBe(502);
    expect(kv.store.size).toBe(0);
  });
});

describe('POST /v1/learn/day', () => {
  it('rejects free tier with 403', async () => {
    const res = await post('/v1/learn/day', 'free', { topic: 'RAG', dayIndex: 2, subtopic: 's2' });
    expect(res.status).toBe(403);
  });

  it('400 when required fields missing', async () => {
    const res = await post('/v1/learn/day', 'pro', { topic: 'RAG' });
    expect(res.status).toBe(400);
  });

  it('expands a single day for Pro', async () => {
    callAI.mockResolvedValueOnce({
      text: JSON.stringify({
        concept: 'Day two concept.',
        cards: [{ question: 'q', answer: 'a', difficulty: 3, layer: 2 }],
        applyPrompt: 'Apply.',
      }),
      resolvedModel: 'gem',
    });
    const res = await post('/v1/learn/day', 'pro', {
      topic: 'RAG',
      dayIndex: 2,
      subtopic: 'reranking',
      objective: 'understand reranking',
      priorSubtopics: ['retrieval'],
    });
    expect(res.status).toBe(200);
    const json = (await res.json()) as { concept: string; cards: unknown[] };
    expect(json.concept).toBe('Day two concept.');
    expect(json.cards).toHaveLength(1);
    expect(callAI).toHaveBeenCalledTimes(1);
  });
});
