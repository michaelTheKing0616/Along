import { assertEquals, assertRejects } from 'jsr:@std/assert@1';
import type { SupabaseClient } from '@supabase/supabase-js';
import { handleTripContact } from './handler.ts';
import {
  contactProviderFromEnv,
  ContactProviderNotConfigured,
  maskedProvider,
  telProvider,
} from '../_shared/contact/mod.ts';

const TRIP = '5c1a9a6e-1f7c-4a3b-9d55-6a2a0f0c1d01';
const RIDER = '5c1a9a6e-1f7c-4a3b-9d55-6a2a0f0c1d02';

function service(result: { data?: unknown; error?: { message: string } }): SupabaseClient {
  return {
    rpc: (_fn: string, _args: unknown) =>
      Promise.resolve({ data: result.data ?? null, error: result.error ?? null }),
  } as unknown as SupabaseClient;
}

const live = {
  data: {
    trip_id: TRIP,
    caller_role: 'rider',
    caller_phone: '+2348000000001',
    target_phone: '+2348031234567',
  },
};

async function call(
  svc: SupabaseClient,
  channel: 'call' | 'sms' = 'call',
  provider = telProvider(() => new Date('2026-10-25T20:00:00Z')),
) {
  const logs: Record<string, unknown>[] = [];
  const res = await handleTripContact({ trip_id: TRIP, channel }, {
    callerId: RIDER,
    service: svc,
    provider,
    log: (e) => logs.push(e),
  });
  return { res, body: await res.json(), logs };
}

Deno.test('live trip: tel provider returns a short-lived tel action', async () => {
  const { res, body, logs } = await call(service(live));
  assertEquals(res.status, 200);
  assertEquals(body.data.uri, 'tel:+2348031234567');
  assertEquals(body.data.masked, false);
  assertEquals(body.data.expires_at, '2026-10-25T20:02:00.000Z');
  assertEquals(logs[0].target_suffix, '4567');
  assertEquals(JSON.stringify(logs).includes('+2348031234567'), false);
});

Deno.test('sms channel returns an sms action', async () => {
  const { body } = await call(service(live), 'sms');
  assertEquals(body.data.uri, 'sms:+2348031234567');
});

Deno.test('deny: caller not on the trip', async () => {
  const { res, body } = await call(service({ error: { message: 'FORBIDDEN' } }));
  assertEquals(res.status, 403);
  assertEquals(body.error.code, 'FORBIDDEN');
});

Deno.test('deny: trip not live', async () => {
  const { res, body } = await call(service({ error: { message: 'STATE_INVALID' } }));
  assertEquals(res.status, 409);
  assertEquals(body.error.code, 'STATE_INVALID');
});

Deno.test('deny: unknown trip', async () => {
  const { res } = await call(service({ error: { message: 'NOT_FOUND' } }));
  assertEquals(res.status, 404);
});

Deno.test('masked provider without credentials fails closed, never leaks the number', async () => {
  const { res, body } = await call(
    service(live),
    'call',
    maskedProvider('termii', {}),
  );
  assertEquals(res.status, 503);
  assertEquals(body.error.code, 'CONTACT_UNAVAILABLE');
  assertEquals(JSON.stringify(body).includes('2348031234567'), false);
});

Deno.test('masked provider with credentials still needs the session API', async () => {
  await assertRejects(
    () =>
      maskedProvider('africastalking', { apiKey: 'k', proxyNumber: '+234700' }).createSession({
        tripId: TRIP,
        channel: 'call',
        callerPhone: '+1',
        targetPhone: '+2',
        ttlSeconds: 60,
      }),
    ContactProviderNotConfigured,
  );
});

Deno.test('provider selection from env', () => {
  assertEquals(contactProviderFromEnv(() => undefined).name, 'tel');
  assertEquals(
    contactProviderFromEnv((k) => (k === 'CONTACT_PROVIDER' ? 'termii' : undefined)).name,
    'termii',
  );
});
