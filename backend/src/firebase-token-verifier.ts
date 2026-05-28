import { jwtVerify, importX509, type JWTPayload } from 'jose';

const GOOGLE_PUBLIC_KEYS_URL =
  'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com';

interface CachedKeys {
  keys: Record<string, string>;
  expiresAt: number;
}

let cachedKeys: CachedKeys | null = null;

async function fetchGooglePublicKeys(): Promise<Record<string, string>> {
  const now = Date.now();
  if (cachedKeys && cachedKeys.expiresAt > now) return cachedKeys.keys;

  const res = await fetch(GOOGLE_PUBLIC_KEYS_URL);
  if (!res.ok) throw new Error(`google-keys-fetch-failed: ${res.status}`);

  const keys = (await res.json()) as Record<string, string>;
  const cacheControl = res.headers.get('cache-control') ?? '';
  const maxAgeMatch = cacheControl.match(/max-age=(\d+)/);
  const maxAgeMs = maxAgeMatch ? parseInt(maxAgeMatch[1], 10) * 1000 : 3600_000;

  cachedKeys = { keys, expiresAt: now + maxAgeMs };
  return keys;
}

export interface FirebaseUser {
  uid: string;
  email?: string;
  emailVerified: boolean;
}

export async function verifyFirebaseIdToken(
  token: string,
  projectId: string,
): Promise<FirebaseUser> {
  const parts = token.split('.');
  if (parts.length !== 3) throw new Error('token-malformed');

  const header = JSON.parse(atob(parts[0].replace(/-/g, '+').replace(/_/g, '/'))) as {
    kid?: string;
    alg?: string;
  };
  if (header.alg !== 'RS256') throw new Error('token-alg-not-rs256');
  if (!header.kid) throw new Error('token-kid-missing');

  const keys = await fetchGooglePublicKeys();
  const pem = keys[header.kid];
  if (!pem) throw new Error('token-kid-unknown');

  const publicKey = await importX509(pem, 'RS256');

  const { payload } = await jwtVerify(token, publicKey, {
    issuer: `https://securetoken.google.com/${projectId}`,
    audience: projectId,
    algorithms: ['RS256'],
  });

  const sub = payload.sub;
  if (typeof sub !== 'string' || sub.length === 0) throw new Error('token-sub-missing');

  const authTime = (payload as JWTPayload & { auth_time?: number }).auth_time;
  if (typeof authTime !== 'number' || authTime > Math.floor(Date.now() / 1000)) {
    throw new Error('token-auth-time-invalid');
  }

  return {
    uid: sub,
    email: typeof payload.email === 'string' ? payload.email : undefined,
    emailVerified: (payload as JWTPayload & { email_verified?: boolean }).email_verified === true,
  };
}
