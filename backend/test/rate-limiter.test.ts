import { describe, it, expect } from 'vitest';
import { peekUsage, commitUsage, type RateLimitConfig } from '../src/rate-limiter';
import { fakeKV } from './fake-kv';

const config: RateLimitConfig = { freeMonthlyLimit: 10, proDailyLimit: 100 };

describe('peekUsage', () => {
  it('reports allowed with full remaining on an empty bucket and does NOT write', async () => {
    const kv = fakeKV();
    const r = await peekUsage(kv, 'u1', 'free', config);
    expect(r.allowed).toBe(true);
    expect(r.used).toBe(0);
    expect(r.remaining).toBe(10);
    expect(kv.store.size).toBe(0); // peek must not increment
  });

  it('blocks once the stored count reaches the free monthly limit', async () => {
    const kv = fakeKV();
    for (let i = 0; i < 10; i++) await commitUsage(kv, 'u1', 'free', config);
    const r = await peekUsage(kv, 'u1', 'free', config);
    expect(r.used).toBe(10);
    expect(r.allowed).toBe(false);
    expect(r.remaining).toBe(0);
  });

  it('treats a corrupt (NaN) stored value as zero', async () => {
    const kv = fakeKV();
    // poison the bucket key directly with a non-numeric value
    const now = new Date();
    const key = `usage:u1:month:${now.getUTCFullYear()}-${String(now.getUTCMonth() + 1).padStart(2, '0')}`;
    kv.store.set(key, 'garbage');
    const r = await peekUsage(kv, 'u1', 'free', config);
    expect(r.used).toBe(0);
    expect(r.allowed).toBe(true);
  });
});

describe('commitUsage', () => {
  it('increments the counter by one and persists it', async () => {
    const kv = fakeKV();
    const r1 = await commitUsage(kv, 'u1', 'free', config);
    expect(r1.used).toBe(1);
    const r2 = await commitUsage(kv, 'u1', 'free', config);
    expect(r2.used).toBe(2);
    expect(r2.remaining).toBe(8);
  });

  it('isolates counters per uid', async () => {
    const kv = fakeKV();
    await commitUsage(kv, 'a', 'free', config);
    await commitUsage(kv, 'a', 'free', config);
    const a = await peekUsage(kv, 'a', 'free', config);
    const b = await peekUsage(kv, 'b', 'free', config);
    expect(a.used).toBe(2);
    expect(b.used).toBe(0);
  });
});

describe('bucket selection by tier', () => {
  it('free tier uses a month bucket; pro tier uses a day bucket (separate keys)', async () => {
    const kv = fakeKV();
    await commitUsage(kv, 'u1', 'free', config);
    await commitUsage(kv, 'u1', 'pro', config);
    const keys = [...kv.store.keys()];
    expect(keys.some((k) => k.includes(':month:'))).toBe(true);
    expect(keys.some((k) => k.includes(':day:'))).toBe(true);
    // free and pro counters are independent buckets
    expect((await peekUsage(kv, 'u1', 'free', config)).used).toBe(1);
    expect((await peekUsage(kv, 'u1', 'pro', config)).used).toBe(1);
  });

  it('applies the pro daily limit for pro tier', async () => {
    const kv = fakeKV();
    const r = await peekUsage(kv, 'u1', 'pro', config);
    expect(r.limit).toBe(100);
    expect(r.remaining).toBe(100);
  });
});
