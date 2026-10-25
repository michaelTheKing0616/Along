/** Mint and cache Google OAuth access tokens for FCM HTTP v1 (Web Crypto only). */

export type FcmServiceAccount = {
  project_id: string;
  client_email: string;
  private_key: string;
  token_uri?: string;
};

type TokenCache = {
  accessToken: string;
  expiresAtMs: number;
};

const FCM_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';
const TOKEN_REFRESH_BUFFER_MS = 60_000;

let tokenCache: TokenCache | null = null;

function base64UrlEncode(data: Uint8Array | string): string {
  const bytes = typeof data === 'string' ? new TextEncoder().encode(data) : data;
  let binary = '';
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function pemToPkcs8(pem: string): ArrayBuffer {
  const normalized = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s/g, '');
  const binary = atob(normalized);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes.buffer;
}

async function importPrivateKey(pem: string): Promise<CryptoKey> {
  return await crypto.subtle.importKey(
    'pkcs8',
    pemToPkcs8(pem),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
}

export function parseFcmServiceAccount(raw: string): FcmServiceAccount {
  const parsed = JSON.parse(raw) as Partial<FcmServiceAccount>;
  if (!parsed.client_email || !parsed.private_key) {
    throw new Error('FCM_SERVICE_ACCOUNT missing client_email or private_key');
  }
  return {
    project_id: parsed.project_id ?? '',
    client_email: parsed.client_email,
    private_key: parsed.private_key,
    token_uri: parsed.token_uri ?? 'https://oauth2.googleapis.com/token',
  };
}

export function resolveFcmProjectId(serviceAccount?: FcmServiceAccount): string | null {
  const fromEnv = Deno.env.get('FCM_PROJECT_ID') ?? Deno.env.get('FIREBASE_PROJECT_ID');
  if (fromEnv?.trim()) return fromEnv.trim();
  const fromAccount = serviceAccount?.project_id?.trim();
  return fromAccount || null;
}

async function signJwt(
  serviceAccount: FcmServiceAccount,
  nowSeconds: number,
): Promise<string> {
  const header = base64UrlEncode(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const payload = base64UrlEncode(JSON.stringify({
    iss: serviceAccount.client_email,
    sub: serviceAccount.client_email,
    aud: serviceAccount.token_uri ?? 'https://oauth2.googleapis.com/token',
    iat: nowSeconds,
    exp: nowSeconds + 3600,
    scope: FCM_SCOPE,
  }));

  const unsigned = `${header}.${payload}`;
  const key = await importPrivateKey(serviceAccount.private_key);
  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    new TextEncoder().encode(unsigned),
  );
  return `${unsigned}.${base64UrlEncode(new Uint8Array(signature))}`;
}

export async function exchangeServiceAccountJwt(
  serviceAccount: FcmServiceAccount,
  fetchFn: (url: string, init: RequestInit) => Promise<Response>,
): Promise<{ accessToken: string; expiresIn: number }> {
  const nowSeconds = Math.floor(Date.now() / 1000);
  const assertion = await signJwt(serviceAccount, nowSeconds);
  const tokenUri = serviceAccount.token_uri ?? 'https://oauth2.googleapis.com/token';

  const res = await fetchFn(tokenUri, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });

  const body = await res.text();
  if (!res.ok) {
    throw new Error(`FCM token exchange failed (${res.status})`);
  }

  const parsed = JSON.parse(body) as { access_token?: string; expires_in?: number };
  if (!parsed.access_token) {
    throw new Error('FCM token exchange returned no access_token');
  }

  return {
    accessToken: parsed.access_token,
    expiresIn: parsed.expires_in ?? 3600,
  };
}

export function clearFcmTokenCacheForTests(): void {
  tokenCache = null;
}

export async function getFcmAccessToken(
  fetchFn: (url: string, init: RequestInit) => Promise<Response> = fetch,
): Promise<string | null> {
  const rawAccount = Deno.env.get('FCM_SERVICE_ACCOUNT');
  if (!rawAccount?.trim()) return null;

  const now = Date.now();
  if (tokenCache && tokenCache.expiresAtMs - TOKEN_REFRESH_BUFFER_MS > now) {
    return tokenCache.accessToken;
  }

  const serviceAccount = parseFcmServiceAccount(rawAccount);
  const { accessToken, expiresIn } = await exchangeServiceAccountJwt(
    serviceAccount,
    fetchFn,
  );

  tokenCache = {
    accessToken,
    expiresAtMs: now + expiresIn * 1000,
  };

  return accessToken;
}
