// Minimal Firestore REST client for Cloudflare Workers. The Node firebase-admin
// SDK doesn't run on Workers, so the daily pipeline talks to the Firestore REST
// API directly, reusing the cached service-account token from firebase-admin.ts.
// Only the value shapes this app needs are encoded/decoded (string, string[],
// map[], timestamp) — not a general Firestore codec.

import { getProjectId, mintAccessToken } from './firebase-admin';

export interface UserProfile {
  topicPacks: string[];
  role?: string;
  level?: string;
  goal?: string;
  seenSkillIds: string[];
}

export interface DailyInboxItem {
  id: string;
  title: string;
  keyword: string;
  whyNow: string;
  coreConcept: string;
  suggestedSearch: string;
  pack: string;
}

function docBase(projectId: string): string {
  return `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents`;
}

// --- decode (only the field types we read) ---

interface FsValue {
  stringValue?: string;
  integerValue?: string;
  arrayValue?: { values?: FsValue[] };
}

function decodeStringArray(v?: FsValue): string[] {
  return (v?.arrayValue?.values ?? []).map((x) => x.stringValue ?? '').filter(Boolean);
}

// --- encode (only the field types we write) ---

function strVal(s: string): FsValue {
  return { stringValue: s };
}

function itemMap(item: DailyInboxItem): { mapValue: { fields: Record<string, FsValue> } } {
  return {
    mapValue: {
      fields: {
        id: strVal(item.id),
        title: strVal(item.title),
        keyword: strVal(item.keyword),
        whyNow: strVal(item.whyNow),
        coreConcept: strVal(item.coreConcept),
        suggestedSearch: strVal(item.suggestedSearch),
        pack: strVal(item.pack),
      },
    },
  };
}

export async function getUserProfile(saJson: string, uid: string): Promise<UserProfile | null> {
  const token = await mintAccessToken(saJson);
  const pid = getProjectId(saJson);
  const res = await fetch(`${docBase(pid)}/users/${uid}`, {
    headers: { authorization: `Bearer ${token}` },
  });
  if (res.status === 404) return null; // no profile doc yet
  if (!res.ok) {
    throw new Error(`firestore get users/${uid}: ${res.status} ${(await res.text()).slice(0, 160)}`);
  }
  const doc = (await res.json()) as { fields?: Record<string, FsValue> };
  const f = doc.fields ?? {};
  return {
    topicPacks: decodeStringArray(f.topicPacks),
    role: f.role?.stringValue,
    level: f.level?.stringValue,
    goal: f.goal?.stringValue,
    seenSkillIds: decodeStringArray(f.seenSkillIds),
  };
}

/// Overwrites daily_inbox/{uid} with today's items (single doc, replaced daily).
export async function writeDailyInbox(
  saJson: string,
  uid: string,
  date: string,
  items: DailyInboxItem[],
  generatedAtISO: string,
): Promise<void> {
  const token = await mintAccessToken(saJson);
  const pid = getProjectId(saJson);
  const body = {
    fields: {
      date: strVal(date),
      generatedAt: { timestampValue: generatedAtISO } as Record<string, unknown>,
      items: { arrayValue: { values: items.map(itemMap) } },
    },
  };
  const res = await fetch(`${docBase(pid)}/daily_inbox/${uid}`, {
    method: 'PATCH',
    headers: { authorization: `Bearer ${token}`, 'content-type': 'application/json' },
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    throw new Error(`firestore write daily_inbox/${uid}: ${res.status} ${(await res.text()).slice(0, 160)}`);
  }
}

/// Appends skill ids to users/{uid}.seenSkillIds via a server-side array-union
/// transform (creates the field if absent). users/{uid} exists post-onboarding.
export async function appendSeenSkillIds(saJson: string, uid: string, ids: string[]): Promise<void> {
  if (ids.length === 0) return;
  const token = await mintAccessToken(saJson);
  const pid = getProjectId(saJson);
  const body = {
    writes: [
      {
        transform: {
          document: `projects/${pid}/databases/(default)/documents/users/${uid}`,
          fieldTransforms: [
            { fieldPath: 'seenSkillIds', appendMissingElements: { values: ids.map(strVal) } },
          ],
        },
      },
    ],
  };
  const res = await fetch(`${docBase(pid)}:commit`, {
    method: 'POST',
    headers: { authorization: `Bearer ${token}`, 'content-type': 'application/json' },
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    // A field transform needs the doc to exist; if it doesn't (NOT_FOUND), there
    // was no prior `seen` to dedupe against — treat as non-fatal so the refresh
    // (inbox already written) doesn't 502. users/{uid} normally exists post-onboarding.
    const detail = (await res.text()).slice(0, 200);
    if (res.status === 404 || detail.includes('NOT_FOUND')) {
      console.warn(`firestore append seen ${uid}: doc missing, skipped`);
      return;
    }
    throw new Error(`firestore append seen ${uid}: ${res.status} ${detail}`);
  }
}
