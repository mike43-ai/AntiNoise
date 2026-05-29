// Daily Knowledge pipeline (curated skill taxonomy). For one user: read profile
// + seen ids, pick unseen candidates for their topic packs, have Gemini choose 3
// and write grounded explainers, persist to daily_inbox, and record the ids as
// seen. No external content API — the taxonomy is bundled.

import { callAI, DAILY_SKILLS_SYSTEM_PROMPT } from './openrouter-client';
import { unseenCandidates, type SkillCandidate } from './skill-taxonomy';
import {
  getUserProfile,
  writeDailyInbox,
  appendSeenSkillIds,
  type DailyInboxItem,
} from './firestore-client';

export interface PipelineEnv {
  OPENROUTER_API_KEY: string;
  OPENROUTER_MODEL: string;
  OPENROUTER_REFERER?: string;
  FIREBASE_SERVICE_ACCOUNT_JSON: string;
}

export type RefreshStatus = 'ok' | 'caught_up' | 'no_profile';

export interface DailyRefreshResult {
  status: RefreshStatus;
  items: DailyInboxItem[];
}

const DAILY_COUNT = 3;
const CANDIDATE_CAP = 24; // keep the prompt small + cheap

interface ModelItem {
  id?: string;
  whyNow?: string;
  coreConcept?: string;
  suggestedSearch?: string;
}

function todayUTC(now: Date): string {
  return now.toISOString().slice(0, 10); // YYYY-MM-DD
}

export async function runDailyRefresh(
  env: PipelineEnv,
  uid: string,
  now: Date = new Date(),
): Promise<DailyRefreshResult> {
  const sa = env.FIREBASE_SERVICE_ACCOUNT_JSON;

  const profile = await getUserProfile(sa, uid);
  if (!profile || profile.topicPacks.length === 0) {
    return { status: 'no_profile', items: [] };
  }

  const seen = new Set(profile.seenSkillIds);
  const candidates = unseenCandidates(profile.topicPacks, seen);
  if (candidates.length === 0) {
    return { status: 'caught_up', items: [] };
  }

  const pool = candidates.slice(0, CANDIDATE_CAP);
  const byId = new Map<string, SkillCandidate>(pool.map((c) => [c.id, c]));

  const userPrompt = JSON.stringify({
    user: { role: profile.role ?? null, level: profile.level ?? null, goal: profile.goal ?? null },
    pick: DAILY_COUNT,
    candidates: pool.map((c) => ({
      id: c.id,
      title: c.title,
      keyword: c.keyword,
      pack: c.pack,
      seedNote: c.seedNote,
    })),
  });

  const { text } = await callAI({
    apiKey: env.OPENROUTER_API_KEY,
    model: env.OPENROUTER_MODEL,
    systemInstruction: DAILY_SKILLS_SYSTEM_PROMPT,
    userPrompt,
    jsonResponse: true,
    temperature: 0.5,
    referer: env.OPENROUTER_REFERER,
    title: 'Anti Noise',
  });

  const parsed = JSON.parse(text) as { items?: ModelItem[] };
  const modelItems = Array.isArray(parsed.items) ? parsed.items : [];

  // Anti-hallucination: keep only items whose id is a real candidate, and take
  // canonical title/keyword/pack from the taxonomy (not the model's echo).
  const items: DailyInboxItem[] = [];
  for (const m of modelItems) {
    const cand = m.id ? byId.get(m.id) : undefined;
    if (!cand) continue;
    if (items.some((i) => i.id === cand.id)) continue; // dedupe
    items.push({
      id: cand.id,
      title: cand.title,
      keyword: cand.keyword,
      pack: cand.pack,
      whyNow: (m.whyNow ?? '').trim() || cand.seedNote,
      coreConcept: (m.coreConcept ?? '').trim() || cand.seedNote,
      suggestedSearch: (m.suggestedSearch ?? '').trim() || `what is ${cand.keyword}`,
    });
    if (items.length >= DAILY_COUNT) break;
  }

  // Fallback: model returned nothing usable → take first N candidates with seedNote.
  if (items.length === 0) {
    for (const c of pool.slice(0, DAILY_COUNT)) {
      items.push({
        id: c.id,
        title: c.title,
        keyword: c.keyword,
        pack: c.pack,
        whyNow: c.seedNote,
        coreConcept: c.seedNote,
        suggestedSearch: `what is ${c.keyword}`,
      });
    }
  }

  await writeDailyInbox(sa, uid, todayUTC(now), items, now.toISOString());
  await appendSeenSkillIds(sa, uid, items.map((i) => i.id));

  return { status: 'ok', items };
}
