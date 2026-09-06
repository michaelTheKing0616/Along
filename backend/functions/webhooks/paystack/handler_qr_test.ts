import { assertEquals } from 'jsr:@std/assert@1';
import type { SupabaseClient } from '@supabase/supabase-js';
import { handlePaystackWebhook } from './handler.ts';
import { verifyPaystackSignature } from '../../_shared/payments/mod.ts';
import type { PaymentNotifyDeps } from '../../_shared/payment_notify.ts';

const SECRET = 'sk_test_paystack_secret_key_12345';
const PAYMENT_ID = '0f800000-0000-4000-8000-000000000090';

async function signBody(body: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(SECRET),
    { name: 'HMAC', hash: 'SHA-512' },
    false,
    ['sign'],
  );
  const digest = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(body));
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

Deno.test('TS-QR-09: webhook payment_id triggers payment_received notify', async () => {
  let notifyCalled = false;
  const service = {
    schema: () => ({
      from: () => ({
        insert: () => Promise.resolve({ error: null }),
      }),
    }),
    rpc: () => Promise.resolve({ data: null, error: null }),
  } as unknown as SupabaseClient;

  const notify: PaymentNotifyDeps = {
    service: {
      from: (table: string) => {
        if (table === 'device_tokens') {
          return {
            select: () => ({
              eq: () => ({
                eq: () => Promise.resolve({ data: [], error: null }),
              }),
            }),
          };
        }
        return {
          select: () => ({
            eq: () => ({
              single: () =>
                Promise.resolve({
                  data: {
                    id: PAYMENT_ID,
                    driver_id: '0f200000-0000-4000-8000-000000000060',
                    amount: 450,
                    driver_amount: 416.25,
                    commission_amount: 33.75,
                    currency: 'NGN',
                    source: 'web_anonymous',
                    trip_id: null,
                  },
                  error: null,
                }),
            }),
          }),
        };
      },
    } as unknown as SupabaseClient,
    realtime: {
      send: async () => {
        notifyCalled = true;
      },
    },
    fcm: {
      sendDataMessage: async () => ({ messageId: 'test' }),
    },
  };

  const payload = {
    event: 'charge.success',
    data: {
      reference: 'web_notify_ref',
      amount: 45000,
      metadata: { payment_id: PAYMENT_ID },
    },
  };
  const body = JSON.stringify(payload);
  const signature = await signBody(body);

  const res = await handlePaystackWebhook(
    new Request('http://localhost/webhooks/paystack', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-paystack-signature': signature,
      },
      body,
    }),
    {
      service,
      paystackSecret: SECRET,
      verifySignature: verifyPaystackSignature,
      notify,
    },
  );

  assertEquals(res.status, 200);
  assertEquals(notifyCalled, true);
});
