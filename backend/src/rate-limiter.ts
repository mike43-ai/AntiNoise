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

export async function checkAndIncrement(
  kv: KVNamespace,
  uid: string,
  tier: Tier,
  config: RateLimitConfig,
): Promise<RateLimitResult> {
  const now = new Date();
  const bucket = tier === 'free' ? monthBucket(uid, now) : dayBucket(uid, now);
  const limit = tier === 'free' ? config.freeMonthlyLimit : config.proDailyLimit;

  const current = parseInt((await kv.get(bucket.key)) ?? '0', 10);
  const used = Number.isFinite(current) ? current : 0;

  if (used >= limit) {
    return {
      allowed: false,
      remaining: 0,
      resetAt: bucket.resetAt,
      used,
      limit,
    };
  }

  const next = used + 1;
  const ttlSeconds = Math.max(60, Math.ceil((bucket.resetAt - now.getTime()) / 1000));
  await kv.put(bucket.key, String(next), { expirationTtl: ttlSeconds });

  return {
    allowed: true,
    remaining: limit - next,
    resetAt: bucket.resetAt,
    used: next,
    limit,
  };
}
