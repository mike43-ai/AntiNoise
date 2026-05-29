import { setUserTier } from './firebase-admin';

// RevenueCat → Firebase custom claim bridge.
//
// RC posts a JSON event to this endpoint. We verify the static Authorization
// header (RC's "shared secret" mechanism — they only support a constant
// bearer-style value, not HMAC), classify the event, then write the resulting
// tier as a Firebase custom claim so the auth middleware reads tier from a
// server-signed JWT instead of a client-attached header.
//
// app_user_id contract: iOS calls Purchases.shared.logIn(firebaseUID) at sign
// in, so RC's app_user_id is the Firebase UID for any user who's signed in.
// Anonymous RC ids (prefix `$RCAnonymousID:`) are ignored — they belong to a
// pre-sign-in session and have no Firebase user to update.

interface RCWebhookBody {
  event?: {
    type?: string;
    app_user_id?: string;
    aliases?: string[];
    original_app_user_id?: string;
    entitlement_ids?: string[] | null;
  };
}

interface WebhookEnv {
  REVENUECAT_WEBHOOK_AUTH: string;
  FIREBASE_SERVICE_ACCOUNT_JSON: string;
}

// Events that should grant pro tier. Anything else (CANCELLATION, EXPIRATION,
// BILLING_ISSUE, SUBSCRIBER_ALIAS, TEST, …) either explicitly downgrades or is
// informational only. TRANSFER is treated as pro because RC fires it during a
// subscription handoff between accounts — the destination should keep entitlement.
const PRO_EVENTS = new Set([
  'INITIAL_PURCHASE',
  'RENEWAL',
  'UNCANCELLATION',
  'NON_RENEWING_PURCHASE',
  'PRODUCT_CHANGE',
  'TRANSFER',
]);

const FREE_EVENTS = new Set([
  'CANCELLATION',
  'EXPIRATION',
  'BILLING_ISSUE',
  'SUBSCRIPTION_PAUSED',
  'REFUND',
]);

// Constant-time string compare — header check is the only thing standing
// between an attacker and a forged grant call to Identity Toolkit.
function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

function pickUid(event: RCWebhookBody['event']): string | null {
  const candidates = [event?.app_user_id, event?.original_app_user_id, ...(event?.aliases ?? [])];
  for (const c of candidates) {
    if (typeof c === 'string' && c.length > 0 && !c.startsWith('$RCAnonymousID:')) {
      return c;
    }
  }
  return null;
}

export async function handleRevenueCatWebhook(req: Request, env: WebhookEnv): Promise<Response> {
  const auth = req.headers.get('authorization') ?? '';
  if (!env.REVENUECAT_WEBHOOK_AUTH || !timingSafeEqual(auth, env.REVENUECAT_WEBHOOK_AUTH)) {
    return new Response(JSON.stringify({ error: 'unauthorized' }), {
      status: 401,
      headers: { 'content-type': 'application/json' },
    });
  }

  let body: RCWebhookBody;
  try {
    body = (await req.json()) as RCWebhookBody;
  } catch {
    return new Response(JSON.stringify({ error: 'bad-json' }), {
      status: 400,
      headers: { 'content-type': 'application/json' },
    });
  }

  const event = body.event;
  const type = event?.type;
  if (!type) {
    return new Response(JSON.stringify({ ok: true, skipped: 'no-event-type' }), {
      headers: { 'content-type': 'application/json' },
    });
  }

  let tier: 'pro' | 'free' | null = null;
  if (PRO_EVENTS.has(type)) tier = 'pro';
  else if (FREE_EVENTS.has(type)) tier = 'free';

  if (!tier) {
    // TEST, SUBSCRIBER_ALIAS, INVOICE_ISSUANCE, etc. Ack so RC doesn't retry.
    return new Response(JSON.stringify({ ok: true, skipped: type }), {
      headers: { 'content-type': 'application/json' },
    });
  }

  const uid = pickUid(event);
  if (!uid) {
    console.warn('rc-webhook.anonymous-or-missing-uid', { type });
    return new Response(JSON.stringify({ ok: true, skipped: 'anonymous-uid' }), {
      headers: { 'content-type': 'application/json' },
    });
  }

  try {
    await setUserTier(env.FIREBASE_SERVICE_ACCOUNT_JSON, uid, tier);
    console.log('rc-webhook.applied', { uid, type, tier });
    return new Response(JSON.stringify({ ok: true, uid, tier }), {
      headers: { 'content-type': 'application/json' },
    });
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'unknown';
    console.error('rc-webhook.set-claim-failed', { uid, type, tier, msg });
    // Return 500 so RC retries (it backs off automatically up to ~72h).
    return new Response(JSON.stringify({ error: 'claim-write-failed' }), {
      status: 500,
      headers: { 'content-type': 'application/json' },
    });
  }
}
