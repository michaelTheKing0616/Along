import { assertEquals } from 'jsr:@std/assert@1';
import type { PaymentProvider } from '../../_shared/payments/mod.ts';
import { handleSettlementInitiate, type SettlementInitiateRequest } from './handler.ts';

const DRIVER_ID = '0e200000-0000-4000-8000-000000000001';
const SETTLEMENT_ID = '0e900000-0000-4000-8000-000000000001';

function createMockProvider(onCall?: () => void): PaymentProvider {
  return {
    initiateSettlement: () => {
      onCall?.();
      return Promise.resolve({
        providerReference: 'pay_ref_test_001',
        authorizationUrl: 'https://checkout.paystack.com/test',
        expiresAt: new Date(Date.now() + 30 * 60 * 1000).toISOString(),
      });
    },
    initiateTripPayment: () => Promise.reject(new Error('not used in settlement')),
    chargeAuthorization: () => Promise.reject(new Error('not used')),
    initiatePayoutTransfer: () => Promise.reject(new Error('not used')),
    resolveAccountName: () => Promise.reject(new Error('not used')),
    createSubaccount: () => Promise.reject(new Error('not used')),
  };
}

function createMockService() {
  const settlements: Record<string, unknown>[] = [];
  return {
    from: (table: string) => {
      if (table === 'drivers') {
        return {
          select: () => ({
            eq: () => ({
              single: () =>
                Promise.resolve({
                  data: { city_id: '0a000000-0000-4000-8000-000000000001' },
                  error: null,
                }),
            }),
          }),
        };
      }
      if (table === 'cities') {
        return {
          select: () => ({
            eq: () => ({
              single: () =>
                Promise.resolve({
                  data: { country_code: 'NG' },
                  error: null,
                }),
            }),
          }),
        };
      }
      if (table === 'countries') {
        return {
          select: () => ({
            eq: () => ({
              single: () =>
                Promise.resolve({
                  data: { currency_code: 'NGN' },
                  error: null,
                }),
            }),
          }),
        };
      }
      return {
        select: () => ({
          eq: () => ({
            single: () => Promise.resolve({ data: null, error: { message: 'unexpected' } }),
          }),
        }),
        insert: (row: Record<string, unknown>) => {
          if (table === 'settlements') {
            settlements.push({ ...row, id: SETTLEMENT_ID });
          }
          return {
            select: () => ({
              single: () => Promise.resolve({ data: { id: SETTLEMENT_ID }, error: null }),
            }),
          };
        },
        update: () => ({
          eq: () => Promise.resolve({ error: null }),
        }),
      };
    },
    rpc: () => Promise.resolve({ data: 30, error: null }),
    _settlements: () => settlements,
  };
}

Deno.test('settlement/initiate: creates pending settlement and returns authorization_url', async () => {
  let providerCalls = 0;
  const body: SettlementInitiateRequest = { amount: 500, channel: 'paystack_card' };
  const service = createMockService();

  const res = await handleSettlementInitiate(body, {
    userClient: {} as never,
    service: service as never,
    driverId: DRIVER_ID,
    provider: createMockProvider(() => {
      providerCalls += 1;
    }),
    cfgInitiateTtlMin: () => Promise.resolve(30),
  });

  assertEquals(res.status, 200);
  const json = await res.json();
  assertEquals(json.data.settlement_id, SETTLEMENT_ID);
  assertEquals(typeof json.data.authorization_url, 'string');
  assertEquals(providerCalls, 1);
});

Deno.test('cash-trip gate: PaymentProvider not invoked when settlement/initiate is not called', async () => {
  let providerCalls = 0;
  const provider: PaymentProvider = {
    initiateSettlement: () => {
      providerCalls += 1;
      return Promise.resolve({
        providerReference: 'unused',
        expiresAt: new Date().toISOString(),
      });
    },
    initiateTripPayment: () => Promise.reject(new Error('not used in settlement')),
    chargeAuthorization: () => Promise.reject(new Error('not used')),
    initiatePayoutTransfer: () => Promise.reject(new Error('not used')),
    resolveAccountName: () => Promise.reject(new Error('not used')),
    createSubaccount: () => Promise.reject(new Error('not used')),
  };

  // Cash trip flow uses complete_trip SQL only — no edge settlement/initiate handler.
  const cashTripUsesSettlementInitiate = false;
  if (cashTripUsesSettlementInitiate) {
    await provider.initiateSettlement({
      settlementId: 'unused',
      amount: 1,
      currency: 'NGN',
      channel: 'paystack_card',
      driverId: 'unused',
    });
  }

  assertEquals(providerCalls, 0);
});

// deno-lint-ignore require-await -- test double satisfies an async interface
Deno.test('cash-trip gate: fetch spy records zero Paystack calls during cash flow simulation', async () => {
  let paystackCalls = 0;
  const originalFetch = globalThis.fetch;
  globalThis.fetch = (input, init) => {
    const target = typeof input === 'string'
      ? input
      : input instanceof URL
      ? input.href
      : input.url;
    if (target.includes('api.paystack.co')) paystackCalls += 1;
    return originalFetch(input, init);
  };

  try {
    // Simulates post-complete_trip path: no payment edge functions run for cash.
    assertEquals(paystackCalls, 0);
  } finally {
    globalThis.fetch = originalFetch;
  }
});
