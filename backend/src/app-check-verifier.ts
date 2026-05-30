import { jwtVerify, createRemoteJWKSet, type JWTVerifyGetKey } from 'jose';

// Firebase App Check tokens are RS256 JWTs signed by Google. Unlike the Firebase
// ID token endpoint (X509 certs), App Check publishes a standard JWKS, so we let
// jose fetch + cache the key set (it honours the endpoint's cache-control).
const APP_CHECK_JWKS_URL = 'https://firebaseappcheck.googleapis.com/v1/jwks';

let jwks: JWTVerifyGetKey | null = null;
function getJwks(): JWTVerifyGetKey {
  if (!jwks) jwks = createRemoteJWKSet(new URL(APP_CHECK_JWKS_URL));
  return jwks;
}

export interface AppCheckClaims {
  // The Firebase App ID the token was minted for (e.g. 1:NNN:ios:HASH).
  appId: string;
}

/**
 * Verify a Firebase App Check token. Proves the request comes from an authentic,
 * unmodified instance of our app (App Attest / DeviceCheck), not a script hitting
 * the API directly. Throws on any failure — caller decides enforce vs. monitor.
 *
 * @param token            raw JWT from the X-Firebase-AppCheck header
 * @param projectNumber    GCP project number (the numeric one, not the project id)
 */
export async function verifyAppCheckToken(
  token: string,
  projectNumber: string,
): Promise<AppCheckClaims> {
  if (!token || token.split('.').length !== 3) throw new Error('appcheck-malformed');

  const { payload } = await jwtVerify(token, getJwks(), {
    issuer: `https://firebaseappcheck.googleapis.com/${projectNumber}`,
    // App Check sets `aud` to an array that includes both the numeric and the
    // string project identifiers; jose treats a string audience as "must be a
    // member of the aud array", which matches.
    audience: `projects/${projectNumber}`,
    algorithms: ['RS256'],
  });

  const sub = payload.sub;
  if (typeof sub !== 'string' || sub.length === 0) throw new Error('appcheck-sub-missing');

  return { appId: sub };
}
