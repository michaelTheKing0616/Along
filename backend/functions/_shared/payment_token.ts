/** HMAC payment tokens — doc 14 §4.2. Must match SQL sign_payment_token/verify_payment_token. */

export type PaymentTokenPayload = {
  tripId: string;
  driverId: string;
  amount: number;
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

export function paymentTokenPayloadText(payload: PaymentTokenPayload): string {
  const amountKobo = Math.round(payload.amount * 100);
  return `${payload.tripId}.${payload.driverId}.${amountKobo}.${payload.exp}`;
}

export async function signPaymentToken(
  key: string,
  payload: PaymentTokenPayload,
): Promise<string> {
  const body = paymentTokenPayloadText(payload);
  const sig = await hmacSha256(key, body);
  return `${btoa(body)}.${encodeBase64(sig)}`;
}

export async function verifyPaymentToken(
  key: string,
  token: string,
  nowSec = Math.floor(Date.now() / 1000),
): Promise<PaymentTokenPayload | null> {
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
  if (segs.length !== 4) return null;
  const exp = Number(segs[3]);
  const amountKobo = Number(segs[2]);
  if (!Number.isFinite(exp) || exp <= nowSec || !Number.isFinite(amountKobo)) return null;

  return { tripId: segs[0], driverId: segs[1], amount: amountKobo / 100, exp };
}
