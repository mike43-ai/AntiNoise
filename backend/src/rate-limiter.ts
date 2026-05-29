export type Tier = 'free' | 'pro';

export interface RateLimitConfig {
  freeMonthlyLimit: number;
  proDailyLimit: number;
}

export interface RateLimitResult {
  allowed: boolean;
  remaining: number;
  resetAt: number;
  used: number;
  limit: number;
}

function monthBucket(uid: string, now: Date): { key: string; resetAt: number } {
  const year = now.getUTCFullYear();
  const month = now.getUTCMonth() + 1;
  const key = `usage:${uid}:month:${year}-${String(month).padStart(2, '0')}`;
  const next = new Date(Date.UTC(year, month, 1));
  return { key, resetAt: next.getTime() };
}

function dayBucket(uid: string, now: Date): { key: string; resetAt: number } {
  const y = now.getUTCFullYear();
  const m = now.getUTCMonth() + 1;
  const d = now.getUTCDate();
  const key = `usage:${uid}:day:${y}-${String(m).padStart(2, '0')}-${String(d).padStart(2, '0')}`;
  const next = new Date(Date.UTC(y, now.getUTCMonth(), d + 1));
  return { key, resetAt: next.getTime() };
}

function resolveBucket(uid: string, tier: Tier, config: RateLimitConfig, now: Date) {
  const bucket = tier === 'free' ? monthBucket(uid, now) : dayBucket(uid, now);
  const limit = tier === 'free' ? config.freeMonthlyLimit : config.proDailyLimit;
  return { bucket, limit };
}

// Read the current usage WITHOUT incrementing. Callers must gate the work on
// `allowed`, run the (failable) work, then call `commitUsage` only on success —
// so a failed upstream AI call never burns a user's quota slot.
export async function peekUsage(
  kv: KVNamespace,
  uid: string,
  tier: Tier,
  config: RateLimitConfig,
): Promise<RateLimitResult> {
  const now = new Date();
  const { bucket, limit } = resolveBucket(uid, tier, config, now);

  const current = parseInt((await kv.get(bucket.key)) ?? '0', 10);
  const used = Number.isFinite(current) ? current : 0;

  return {
    allowed: used < limit,
    remaining: Math.max(0, limit - used),
    resetAt: bucket.resetAt,
    used,
    limit,
  };
}

// Increment the usage counter by one. Re-reads the live value so concurrent
// requests don't clobber each other's increment. Call ONLY after the work that
// the slot pays for has fully succeeded.
export async function commitUsage(
  kv: KVNamespace,
  uid: string,
  tier: Tier,
  config: RateLimitConfig,
): Promise<RateLimitResult> {
  const now = new Date();
  const { bucket, limit } = resolveBucket(uid, tier, config, now);

  const current = parseInt((await kv.get(bucket.key)) ?? '0', 10);
  const used = Number.isFinite(current) ? current : 0;
  const next = used + 1;

  const ttlSeconds = Math.max(60, Math.ceil((bucket.resetAt - now.getTime()) / 1000));
  await kv.put(bucket.key, String(next), { expirationTtl: ttlSeconds });

  return {
    allowed: next <= limit,
    remaining: Math.max(0, limit - next),
    resetAt: bucket.resetAt,
    used: next,
    limit,
  };
}
