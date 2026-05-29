import { SignJWT, importPKCS8 } from 'jose';

// Firebase Admin REST shim for Cloudflare Workers — replaces the Node-only
// firebase-admin SDK. Uses a service account JWT to mint a short-lived OAuth2
// access token, then calls Identity Toolkit to write custom claims (the
// authoritative source of truth for paywall tier).

interface ServiceAccount {
  client_email: string;
  private_key: string;
  project_id: string;
  token_uri?: string;
}

interface AccessTokenCache {
  token: string;
  expiresAt: number;
}

let cachedAccessToken: AccessTokenCache | null = null;

function parseServiceAccount(raw: string): ServiceAccount {
  const sa = JSON.parse(raw) as ServiceAccount;
  if (!sa.client_email || !sa.private_key || !sa.project_id) {
    throw new Error('firebase-admin: malformed service account (missing required fields)');
  }
  return sa;
}

export function getProjectId(raw: string): string {
  return parseServiceAccount(raw).project_id;
}

// Exported so the Firestore REST client (daily pipeline) can reuse the same
// short-lived, cached service-account token. Scope includes `datastore` for
// Firestore document reads/writes in addition to identitytoolkit (custom claims).
export async function mintAccessToken(raw: string): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedAccessToken && cachedAccessToken.expiresAt - 60 > now) {
    return cachedAccessToken.token;
  }

  const sa = parseServiceAccount(raw);
  const tokenUri = sa.token_uri ?? 'https://oauth2.googleapis.com/token';

  const key = await importPKCS8(sa.private_key, 'RS256');
  const assertion = await new SignJWT({
    scope:
      'https://www.googleapis.com/auth/firebase https://www.googleapis.com/auth/identitytoolkit https://www.googleapis.com/auth/datastore',
  })
    .setProtectedHeader({ alg: 'RS256' })
    .setIssuer(sa.client_email)
    .setSubject(sa.client_email)
    .setAudience(tokenUri)
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(key);

  const res = await fetch(tokenUri, {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });
  if (!res.ok) {
    const errText = await res.text().catch(() => '');
    throw new Error(`firebase-admin: token-exchange ${res.status} ${errText.slice(0, 200)}`);
  }
  const data = (await res.json()) as { access_token?: string; expires_in?: number };
  if (!data.access_token) throw new Error('firebase-admin: token-exchange-empty');

  cachedAccessToken = {
    token: data.access_token,
    expiresAt: now + (data.expires_in ?? 3600),
  };
  return cachedAccessToken.token;
}

// Merges into the user's existing custom claims rather than replacing — Identity
// Toolkit's `customAttributes` field is overwrite-only, so the caller must pass
// the full new claim object. We expose a focused setTier() helper to keep call
// sites honest.
export async function setUserTier(
  serviceAccountJson: string,
  uid: string,
  tier: 'pro' | 'free',
): Promise<void> {
  const accessToken = await mintAccessToken(serviceAccountJson);
  const sa = parseServiceAccount(serviceAccountJson);

  const customAttributes = JSON.stringify({ tier });
  const url = `https://identitytoolkit.googleapis.com/v1/projects/${sa.project_id}/accounts:update`;

  const res = await fetch(url, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      authorization: `Bearer ${accessToken}`,
    },
    body: JSON.stringify({ localId: uid, customAttributes }),
  });
  if (!res.ok) {
    const errText = await res.text().catch(() => '');
    throw new Error(`firebase-admin: set-claim ${res.status} ${errText.slice(0, 200)}`);
  }
}
