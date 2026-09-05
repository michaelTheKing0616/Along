/** Standard Webhooks signature verification (Web Crypto only). */

function decodeBase64(input: string): Uint8Array {
  const normalized = input.replace(/-/g, '+').replace(/_/g, '/');
  const padded = normalized + '='.repeat((4 - (normalized.length % 4)) % 4);
  const binary = atob(padded);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

function parseHookSecrets(raw: string | undefined): Uint8Array[] {
  if (!raw?.trim()) return [];
  return raw.split('|').map((entry) => {
    const secret = entry.trim().replace(/^v1,whsec_/, '');
    return decodeBase64(secret);
  });
}

async function hmacSha256Base64(secret: Uint8Array, payload: string): Promise<string> {
  const keyMaterial = new Uint8Array(secret);
  const key = await crypto.subtle.importKey(
    'raw',
    keyMaterial,
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signature = await crypto.subtle.sign(
    'HMAC',
    key,
    new TextEncoder().encode(payload),
  );
  let binary = '';
  for (const byte of new Uint8Array(signature)) binary += String.fromCharCode(byte);
  return btoa(binary);
}

export async function verifyStandardWebhook(
  payload: string,
  headers: Headers,
  secretsRaw: string | undefined,
): Promise<unknown> {
  const secrets = parseHookSecrets(secretsRaw);
  if (secrets.length === 0) {
    throw new Error('SEND_SMS_HOOK_SECRETS not configured');
  }

  const webhookId = headers.get('webhook-id');
  const webhookTimestamp = headers.get('webhook-timestamp');
  const webhookSignature = headers.get('webhook-signature');
  if (!webhookId || !webhookTimestamp || !webhookSignature) {
    throw new Error('Missing webhook headers');
  }

  const signedContent = `${webhookId}.${webhookTimestamp}.${payload}`;
  const signatures = webhookSignature.split(' ');
  let verified = false;

  for (const secret of secrets) {
    const expected = await hmacSha256Base64(secret, signedContent);
    for (const sig of signatures) {
      const [version, value] = sig.split(',', 2);
      if (version === 'v1' && value === expected) {
        verified = true;
        break;
      }
    }
    if (verified) break;
  }

  if (!verified) {
    throw new Error('Invalid webhook signature');
  }

  return JSON.parse(payload) as unknown;
}
