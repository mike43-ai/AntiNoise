import { describe, it, expect, vi, beforeEach } from 'vitest';

// Mock the two side-effecting collaborators so we can drive the pipeline's logic
// (anti-hallucination filtering, dedupe, fallback, persistence) deterministically.
const callAI = vi.fn();
const getUserProfile = vi.fn();
const writeDailyInbox = vi.fn();
const appendSeenSkillIds = vi.fn();

vi.mock('../src/openrouter-client', () => ({
  callAI: (...args: unknown[]) => callAI(...args),
  DAILY_SKILLS_SYSTEM_PROMPT: 'SYS',
}));
vi.mock('../src/firestore-client', () => ({
  getUserProfile: (...args: unknown[]) => getUserProfile(...args),
  writeDailyInbox: (...args: unknown[]) => writeDailyInbox(...args),
  appendSeenSkillIds: (...args: unknown[]) => appendSeenSkillIds(...args),
}));

import { runDailyRefresh, type PipelineEnv } from '../src/daily-pipeline';

const env: PipelineEnv = {
  OPENROUTER_API_KEY: 'k',
  OPENROUTER_MODEL: 'm',
  FIREBASE_SERVICE_ACCOUNT_JSON: '{}',
};

beforeEach(() => {
  callAI.mockReset();
  getUserProfile.mockReset();
  writeDailyInbox.mockReset();
  appendSeenSkillIds.mockReset();
  writeDailyInbox.mockResolvedValue(undefined);
  appendSeenSkillIds.mockResolvedValue(undefined);
});

describe('runDailyRefresh — guard paths', () => {
  it('returns no_profile when the user has no profile', async () => {
    getUserProfile.mockResolvedValue(null);
    const r = await runDailyRefresh(env, 'u1');
    expect(r.status).toBe('no_profile');
    expect(r.items).toEqual([]);
    expect(callAI).not.toHaveBeenCalled();
  });

  it('returns no_profile when topicPacks is empty', async () => {
    getUserProfile.mockResolvedValue({ topicPacks: [], seenSkillIds: [] });
    const r = await runDailyRefresh(env, 'u1');
    expect(r.status).toBe('no_profile');
    expect(callAI).not.toHaveBeenCalled();
  });

  it('returns caught_up (no AI call) when every candidate is already seen', async () => {
    // aiml pack fully seen → unseenCandidates empty
    const { SKILL_TAXONOMY } = await import('../src/skill-taxonomy');
    getUserProfile.mockResolvedValue({
      topicPacks: ['aiml'],
      seenSkillIds: SKILL_TAXONOMY.aiml.map((i) => i.id),
    });
    const r = await runDailyRefresh(env, 'u1');
    expect(r.status).toBe('caught_up');
    expect(callAI).not.toHaveBeenCalled();
    expect(writeDailyInbox).not.toHaveBeenCalled();
  });
});

describe('runDailyRefresh — ok path', () => {
  beforeEach(() => {
    getUserProfile.mockResolvedValue({
      topicPacks: ['aiml'],
      role: 'Engineer',
      level: '5+y',
      goal: 'Learn skills',
      seenSkillIds: [],
    });
  });

  it('keeps only real candidate ids, uses canonical taxonomy fields, and persists', async () => {
    callAI.mockResolvedValue({
      text: JSON.stringify({
        items: [
          { id: 'aiml-rag', whyNow: 'hot now', coreConcept: 'retrieve then generate', suggestedSearch: 'rag tutorial' },
          { id: 'totally-fake-id', whyNow: 'x', coreConcept: 'y', suggestedSearch: 'z' }, // dropped
          { id: 'aiml-evals', whyNow: 'measure', coreConcept: 'score outputs', suggestedSearch: 'llm evals' },
          { id: 'aiml-agents', whyNow: 'loops', coreConcept: 'plan + act', suggestedSearch: 'agents' },
        ],
      }),
    });

    const r = await runDailyRefresh(env, 'u1');
    expect(r.status).toBe('ok');
    expect(r.items.map((i) => i.id)).toEqual(['aiml-rag', 'aiml-evals', 'aiml-agents']);
    // canonical title comes from taxonomy, not the model echo
    expect(r.items[0].title).toBe('Retrieval-Augmented Generation');
    expect(r.items[0].whyNow).toBe('hot now');
    // persistence: inbox written + ids recorded as seen
    expect(writeDailyInbox).toHaveBeenCalledOnce();
    expect(appendSeenSkillIds).toHaveBeenCalledWith('{}', 'u1', ['aiml-rag', 'aiml-evals', 'aiml-agents']);
  });

  it('caps at 3 items even if the model returns more valid ids', async () => {
    callAI.mockResolvedValue({
      text: JSON.stringify({
        items: ['aiml-rag', 'aiml-evals', 'aiml-agents', 'aiml-embeddings', 'aiml-context'].map((id) => ({
          id,
          whyNow: 'w',
          coreConcept: 'c',
          suggestedSearch: 's',
        })),
      }),
    });
    const r = await runDailyRefresh(env, 'u1');
    expect(r.items.length).toBe(3);
  });

  it('dedupes a model that repeats the same id', async () => {
    callAI.mockResolvedValue({
      text: JSON.stringify({
        items: [
          { id: 'aiml-rag', whyNow: 'a', coreConcept: 'a', suggestedSearch: 'a' },
          { id: 'aiml-rag', whyNow: 'b', coreConcept: 'b', suggestedSearch: 'b' },
          { id: 'aiml-evals', whyNow: 'c', coreConcept: 'c', suggestedSearch: 'c' },
        ],
      }),
    });
    const r = await runDailyRefresh(env, 'u1');
    expect(r.items.map((i) => i.id)).toEqual(['aiml-rag', 'aiml-evals']);
  });

  it('falls back to seedNote when the model omits text fields', async () => {
    callAI.mockResolvedValue({ text: JSON.stringify({ items: [{ id: 'aiml-rag' }] }) });
    const r = await runDailyRefresh(env, 'u1');
    expect(r.items[0].whyNow.length).toBeGreaterThan(0); // filled from candidate seedNote
    expect(r.items[0].suggestedSearch).toBe('what is RAG');
  });

  it('falls back to first N candidates when the model returns nothing usable', async () => {
    callAI.mockResolvedValue({ text: JSON.stringify({ items: [] }) });
    const r = await runDailyRefresh(env, 'u1');
    expect(r.status).toBe('ok');
    expect(r.items.length).toBe(3);
    expect(writeDailyInbox).toHaveBeenCalledOnce();
  });
});
