/** HMAC candidate tokens — doc 03 §4, doc 01 §6.4. Must match SQL sign_candidate_token/verify. */

export type CandidateTokenPayload = {
  driverId: string;
  sessionId: string;
  exp: number;
};

function encodeBase64(bytes: Uint8Array): string {
  let binary = '';
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary);
}

async function hmacSha256(key: string, payload: string): Promise<Uint8Array> {
  const keyBytes = new TextEncoder().encode(key);
  const cryptoKey = await crypto.subtle.importKey(
    'raw',
    keyBytes,
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const sig = await crypto.subtle.sign(
    'HMAC',
    cryptoKey,
    new TextEncoder().encode(payload),
  );
  return new Uint8Array(sig);
}

export function candidateTokenPayloadText(payload: CandidateTokenPayload): string {
  return `${payload.driverId}.${payload.sessionId}.${payload.exp}`;
}

export async function signCandidateToken(
  key: string,
  payload: CandidateTokenPayload,
): Promise<string> {
  const body = candidateTokenPayloadText(payload);
  const sig = await hmacSha256(key, body);
  return `${btoa(body)}.${encodeBase64(sig)}`;
}

export async function verifyCandidateToken(
  key: string,
  token: string,
  nowSec = Math.floor(Date.now() / 1000),
): Promise<CandidateTokenPayload | null> {
  const parts = token.split('.');
  if (parts.length !== 2) return null;

  let body: string;
  let sigBytes: Uint8Array;
  try {
    body = atob(parts[0]);
    const sigBin = atob(parts[1]);
    sigBytes = new Uint8Array(sigBin.length);
    for (let i = 0; i < sigBin.length; i++) sigBytes[i] = sigBin.charCodeAt(i);
  } catch {
    return null;
  }

  const expected = await hmacSha256(key, body);
  if (expected.length !== sigBytes.length) return null;
  let diff = 0;
  for (let i = 0; i < expected.length; i++) diff |= expected[i] ^ sigBytes[i];
  if (diff !== 0) return null;

  const segs = body.split('.');
  if (segs.length !== 3) return null;
  const exp = Number(segs[2]);
  if (!Number.isFinite(exp) || exp <= nowSec) return null;

  return { driverId: segs[0], sessionId: segs[1], exp };
}
