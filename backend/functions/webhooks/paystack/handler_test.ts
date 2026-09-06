import { assertEquals } from 'jsr:@std/assert@1';
import type { SupabaseClient } from '@supabase/supabase-js';
import {
  handlePaystackWebhook,
  paystackEventSchema,
} from './handler.ts';
import { verifyPaystackSignature } from '../../_shared/payments/paystack_verify.ts';

const SECRET = 'sk_test_paystack_secret_key_12345';

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

type StoredWebhook = { signature_ok: boolean; body: Record<string, unknown> };

function createMockService(options: {
  rpcCalls?: string[];
  ledgerCount?: number;
}): SupabaseClient {
  const stored: StoredWebhook[] = [];
  let ledgerCount = options.ledgerCount ?? 0;

  return {
    schema: () => ({
      from: () => ({
        insert: (row: StoredWebhook) => {
          stored.push(row);
          return Promise.resolve({ error: null });
        },
      }),
    }),
    rpc: (name: string) => {
      options.rpcCalls?.push(name);
      if (name === 'apply_paystack_charge_success') {
        ledgerCount += 1;
      }
      return Promise.resolve({ data: { id: ledgerCount }, error: null });
    },
    _stored: () => stored,
    _ledgerCount: () => ledgerCount,
  } as unknown as SupabaseClient & {
    _stored: () => StoredWebhook[];
    _ledgerCount: () => number;
  };
}

Deno.test('TS-LEDGER-08: bad signature → 401, raw stored signature_ok=false, no ledger row', async () => {
  const rpcCalls: string[] = [];
  const service = createMockService({ rpcCalls });
  const body = JSON.stringify({ event: 'charge.success', data: { reference: 'bad_sig_ref' } });

  const res = await handlePaystackWebhook(
    new Request('http://localhost/webhooks/paystack', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-paystack-signature': 'deadbeef',
      },
      body,
    }),
    {
      service,
      paystackSecret: SECRET,
      verifySignature: verifyPaystackSignature,
    },
  );

  assertEquals(res.status, 401);
  assertEquals(rpcCalls.length, 0);
  const stored = (service as ReturnType<typeof createMockService> & { _stored: () => StoredWebhook[] })
    ._stored();
  assertEquals(stored.length, 1);
  assertEquals(stored[0]?.signature_ok, false);
});

Deno.test('TS-LEDGER-08: duplicate reference → single ledger row via idempotent rpc', async () => {
  const rpcCalls: string[] = [];
  const service = createMockService({ rpcCalls });
  const payload = {
    event: 'charge.success',
    data: {
      reference: 'dup_ref_001',
      amount: 500000,
      metadata: { settlement_id: '0e900000-0000-4000-8000-000000000001' },
    },
  };
  const body = JSON.stringify(payload);
  const signature = await signBody(body);

  const makeReq = () =>
    new Request('http://localhost/webhooks/paystack', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-paystack-signature': signature,
      },
      body,
    });

  const res1 = await handlePaystackWebhook(makeReq(), {
    service,
    paystackSecret: SECRET,
    verifySignature: verifyPaystackSignature,
  });
  const res2 = await handlePaystackWebhook(makeReq(), {
    service,
    paystackSecret: SECRET,
    verifySignature: verifyPaystackSignature,
  });

  assertEquals(res1.status, 200);
  assertEquals(res2.status, 200);
  assertEquals(rpcCalls.filter((c) => c === 'apply_paystack_charge_success').length, 2);
});

Deno.test('paystack event schema accepts charge.success', () => {
  const parsed = paystackEventSchema.safeParse({
    event: 'charge.success',
    data: { reference: 'x', amount: 100, metadata: { trip_id: 'abc' } },
  });
  assertEquals(parsed.success, true);
});
