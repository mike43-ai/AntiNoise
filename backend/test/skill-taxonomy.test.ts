import { describe, it, expect } from 'vitest';
import { SKILL_TAXONOMY, unseenCandidates } from '../src/skill-taxonomy';

describe('SKILL_TAXONOMY integrity', () => {
  it('has globally unique skill ids across all packs', () => {
    const ids = Object.values(SKILL_TAXONOMY).flatMap((items) => items.map((i) => i.id));
    expect(new Set(ids).size).toBe(ids.length);
  });

  it('uses pack ids that match the iOS TopicPack rawValues', () => {
    const expected = ['aiml', 'engineering', 'productDesign', 'startup', 'productivity'];
    expect(Object.keys(SKILL_TAXONOMY).sort()).toEqual([...expected].sort());
  });

  it('gives every item a non-empty keyword + seedNote (anti-hallucination anchors)', () => {
    for (const items of Object.values(SKILL_TAXONOMY)) {
      for (const it of items) {
        expect(it.keyword.length).toBeGreaterThan(0);
        expect(it.seedNote.length).toBeGreaterThan(0);
      }
    }
  });
});

describe('unseenCandidates', () => {
  it('returns all items for a pack when nothing is seen, tagged with the pack id', () => {
    const out = unseenCandidates(['aiml'], new Set());
    expect(out.length).toBe(SKILL_TAXONOMY.aiml.length);
    expect(out.every((c) => c.pack === 'aiml')).toBe(true);
  });

  it('excludes already-seen ids', () => {
    const seen = new Set(['aiml-rag', 'aiml-evals']);
    const out = unseenCandidates(['aiml'], seen);
    expect(out.length).toBe(SKILL_TAXONOMY.aiml.length - 2);
    expect(out.some((c) => seen.has(c.id))).toBe(false);
  });

  it('merges multiple packs', () => {
    const out = unseenCandidates(['aiml', 'engineering'], new Set());
    expect(out.length).toBe(SKILL_TAXONOMY.aiml.length + SKILL_TAXONOMY.engineering.length);
  });

  it('ignores unknown pack ids without throwing', () => {
    expect(unseenCandidates(['does-not-exist'], new Set())).toEqual([]);
  });

  it('returns empty when every candidate in the pack is seen', () => {
    const seen = new Set(SKILL_TAXONOMY.aiml.map((i) => i.id));
    expect(unseenCandidates(['aiml'], seen)).toEqual([]);
  });
});
