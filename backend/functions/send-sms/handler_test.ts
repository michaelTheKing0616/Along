import { assertEquals } from 'jsr:@std/assert@1';
import type { SupabaseClient } from '@supabase/supabase-js';
import { handleSendSms } from './handler.ts';

const USER_ID = '6481a5c1-3d37-4a56-9f6a-bee08c554965';
const HOOK_SECRET = btoa('test-secret-key-1234567890123456');

async function signedRequest(body: unknown): Promise<Request> {
  const payload = JSON.stringify(body);
  const webhookId = 'msg_test';
  const webhookTimestamp = String(Math.floor(Date.now() / 1000));
  const secretBytes = Uint8Array.from(atob(HOOK_SECRET), (c) => c.charCodeAt(0));
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

  return new Request('http://localhost/send-sms', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'webhook-id': webhookId,
      'webhook-timestamp': webhookTimestamp,
      'webhook-signature': `v1,${btoa(binary)}`,
    },
    body: payload,
  });
}

function createMockService(provider = 'log'): SupabaseClient {
  return {
    rpc: (name: string, args?: Record<string, unknown>) => {
      if (name === 'cfg' && args?.p_key === 'sms.provider') {
        return Promise.resolve({ data: JSON.stringify(provider), error: null });
      }
      return Promise.resolve({ data: null, error: { message: `unexpected rpc: ${name}` } });
    },
  } as unknown as SupabaseClient;
}

Deno.test('send-sms: log provider writes structured OTP log', async () => {
  const logs: Record<string, unknown>[] = [];
  const req = await signedRequest({
    user: { id: USER_ID, phone: '+2348012345678' },
    sms: { otp: '561166' },
  });

  const res = await handleSendSms(req, {
    service: createMockService('log'),
    hookSecrets: `v1,whsec_${HOOK_SECRET}`,
    log: (entry) => logs.push(entry),
  });

  assertEquals(res.status, 200);
  assertEquals(logs.length, 1);
  assertEquals(logs[0]?.event, 'sms_otp_log');
  assertEquals(logs[0]?.otp, '561166');
  assertEquals(logs[0]?.phone_suffix, '5678');
});

Deno.test('send-sms: rejects non-log provider until Termii is wired', async () => {
  const req = await signedRequest({
    user: { id: USER_ID, phone: '+2348012345678' },
    sms: { otp: '561166' },
  });

  const res = await handleSendSms(req, {
    service: createMockService('termii'),
    hookSecrets: `v1,whsec_${HOOK_SECRET}`,
    log: () => undefined,
  });

  assertEquals(res.status, 501);
});

Deno.test('send-sms: rejects unsigned webhook', async () => {
  const req = new Request('http://localhost/send-sms', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      user: { id: USER_ID, phone: '+2348012345678' },
      sms: { otp: '561166' },
    }),
  });

  const res = await handleSendSms(req, {
    service: createMockService('log'),
    hookSecrets: `v1,whsec_${HOOK_SECRET}`,
    log: () => undefined,
  });

  assertEquals(res.status, 401);
});
