import { assertEquals } from 'jsr:@std/assert@1';
import { verifyStandardWebhook } from './webhook_verify.ts';

async function signPayload(
  secretB64: string,
  payload: string,
  webhookId = 'msg_123',
  webhookTimestamp = '1715600000',
): Promise<Headers> {
  const secretBytes = Uint8Array.from(atob(secretB64), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    'raw',
    secretBytes,
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signedContent = `${webhookId}.${webhookTimestamp}.${payload}`;
  const signature = await crypto.subtle.sign(
    'HMAC',
    key,
    new TextEncoder().encode(signedContent),
  );
  let binary = '';
  for (const byte of new Uint8Array(signature)) binary += String.fromCharCode(byte);
  const sig = btoa(binary);

  const headers = new Headers();
  headers.set('webhook-id', webhookId);
  headers.set('webhook-timestamp', webhookTimestamp);
  headers.set('webhook-signature', `v1,${sig}`);
  return headers;
}

Deno.test('verifyStandardWebhook: accepts valid signature', async () => {
  const secret = btoa('test-secret-key-1234567890123456');
  const payload = '{"hello":"world"}';
  const headers = await signPayload(secret, payload);
  const verified = await verifyStandardWebhook(payload, headers, `v1,whsec_${secret}`);
  assertEquals(verified, { hello: 'world' });
});

Deno.test('verifyStandardWebhook: rejects invalid signature', async () => {
  const secret = btoa('test-secret-key-1234567890123456');
  const payload = '{"hello":"world"}';
  const headers = new Headers({
    'webhook-id': 'msg_123',
    'webhook-timestamp': '1715600000',
    'webhook-signature': 'v1,invalid',
  });

  let failed = false;
  try {
    await verifyStandardWebhook(payload, headers, `v1,whsec_${secret}`);
  } catch {
    failed = true;
  }
  assertEquals(failed, true);
});
