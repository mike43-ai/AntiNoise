import { describe, it, expect } from 'vitest';
import { verifyAppCheckToken } from '../src/app-check-verifier';
import app from '../src/index';

// Minimal env for the /v1/* middleware. Only the App Check fields matter here;
// requests in these tests never reach the AI handlers (they stop at App Check or
// at the auth check), so the OpenRouter/Firebase/KV bindings can be stubbed.
function env(overrides: Record<string, unknown> = {}) {
  return {
    FIREBASE_PROJECT_NUMBER: '783988295054',
    FIREBASE_PROJECT_ID: 'antinoise-6601f',
    OPENROUTER_API_KEY: 'x',
    OPENROUTER_MODEL: 'x',
    FIREBASE_SERVICE_ACCOUNT_JSON: '{}',
    REVENUECAT_WEBHOOK_AUTH: 'x',
    FREE_MONTHLY_LIMIT: '10',
    PRO_DAILY_LIMIT: '200',
    RATE_LIMIT: {},
    ...overrides,
  };
}

describe('verifyAppCheckToken', () => {
  it('rejects a token that is not a 3-part JWT (no network call)', async () => {
    await expect(verifyAppCheckToken('not-a-jwt', '783988295054')).rejects.toThrow(
      'appcheck-malformed',
    );
  });

  it('rejects an empty token', async () => {
    await expect(verifyAppCheckToken('', '783988295054')).rejects.toThrow('appcheck-malformed');
  });
});

describe('/v1/* App Check gating', () => {
  it('monitor mode (default): a missing App Check token does NOT block — request falls through to the auth check', async () => {
    const res = await app.request('/v1/ai/summarize', { method: 'POST' }, env());
    // App Check passed through; the request is rejected later for the missing
    // bearer token, proving App Check did not short-circuit it.
    expect(res.status).toBe(401);
    expect(await res.json()).toEqual({ error: 'auth-missing' });
  });

  it('enforce mode: a missing App Check token is rejected with appcheck-missing', async () => {
    const res = await app.request(
      '/v1/ai/summarize',
      { method: 'POST' },
      env({ APP_CHECK_ENFORCE: 'true' }),
    );
    expect(res.status).toBe(401);
    expect(await res.json()).toEqual({ error: 'appcheck-missing' });
  });

  it('enforce mode: a malformed App Check token is rejected with appcheck-invalid', async () => {
    const res = await app.request(
      '/v1/ai/summarize',
      { method: 'POST', headers: { 'x-firebase-appcheck': 'garbage' } },
      env({ APP_CHECK_ENFORCE: 'true' }),
    );
    expect(res.status).toBe(401);
    const body = (await res.json()) as { error: string; detail: string };
    expect(body.error).toBe('appcheck-invalid');
    expect(body.detail).toBe('appcheck-malformed');
  });
});
