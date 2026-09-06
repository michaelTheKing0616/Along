import { assertEquals } from 'jsr:@std/assert@1';
import type { PaymentProvider, TripPaymentInitiateParams } from '../../_shared/payments/mod.ts';
import {
  handlePaymentInitiate,
  paymentInitiateSchema,
} from './handler.ts';

const RIDER_ID = '0f100000-0000-4000-8000-000000000030';
const DRIVER_ID = '0f200000-0000-4000-8000-000000000030';
const TRIP_ID = '0f700000-0000-4000-8000-000000000030';
const PAYMENT_ID = '0f800000-0000-4000-8000-000000000030';
const CITY_ID = '0a000000-0000-4000-8000-000000000001';
const DRIVER_CODE = 'TEST0301';

const TRIP_ROW = {
  id: TRIP_ID,
  rider_id: RIDER_ID,
  driver_id: DRIVER_ID,
  fare_shown: 800,
  load_surcharge_amount: 50,
  fare_currency: 'NGN',
  commission_rate: 0.05,
  commission_amount: null,
  status: 'completed',
  payment_method: 'cash',
};

const DRIVER_ROW = {
  id: DRIVER_ID,
  city_id: CITY_ID,
  payout_subaccount_code: 'ACCT_test_sub',
  accepts_digital: true,
  driver_code: DRIVER_CODE,
};

function createMockProvider(onCall?: (params: TripPaymentInitiateParams) => void): PaymentProvider {
  return {
    initiateSettlement: () => Promise.reject(new Error('not used')),
    initiateTripPayment: (params) => {
      onCall?.(params);
      return Promise.resolve({
        providerReference: 'pay_ref_test_001',
        authorizationUrl: 'https://checkout.paystack.com/test',
        expiresAt: new Date(Date.now() + 30 * 60 * 1000).toISOString(),
      });
    },
    chargeAuthorization: () => Promise.reject(new Error('not used')),
    initiatePayoutTransfer: () => Promise.reject(new Error('not used')),
    resolveAccountName: () => Promise.reject(new Error('not used')),
    createSubaccount: () => Promise.reject(new Error('not used')),
  };
}

function createMockService(options?: {
  digitalEnabled?: boolean;
  existingPaid?: boolean;
  driverRow?: typeof DRIVER_ROW;
  tripPayableTotal?: number;
  otherActiveTrip?: boolean;
}) {
  const payments: Record<string, unknown>[] = [];
  const digitalEnabled = options?.digitalEnabled ?? true;
  const driverRow = options?.driverRow ?? DRIVER_ROW;

  return {
    from: (table: string) => {
      if (table === 'trips') {
        const tripResult = { data: TRIP_ROW, error: null };
        const chain = {
          eq: (_col: string, _val: unknown) => ({
            ...chain,
            single: () => Promise.resolve(tripResult),
            neq: () => ({
              limit: () => ({
                maybeSingle: () =>
                  Promise.resolve({
                    data: options?.otherActiveTrip ? { id: 'other' } : null,
                    error: null,
                  }),
              }),
            }),
            limit: () => ({
              maybeSingle: () => Promise.resolve({ data: null, error: null }),
            }),
          }),
          in: () => ({
            neq: () => ({
              limit: () => ({
                maybeSingle: () =>
                  Promise.resolve({
                    data: options?.otherActiveTrip ? { id: 'other' } : null,
                    error: null,
                  }),
              }),
            }),
          }),
          single: () => Promise.resolve(tripResult),
        };
        return {
          select: () => chain,
        };
      }
      if (table === 'drivers') {
        return {
          select: () => ({
            eq: () => ({
              single: () => Promise.resolve({ data: driverRow, error: null }),
            }),
          }),
        };
      }
      if (table === 'payments') {
        return {
          select: () => ({
            eq: (_col: string, val: unknown) => ({
              eq: () => ({
                maybeSingle: () =>
                  Promise.resolve({
                    data: options?.existingPaid ? { id: 'existing', receipt_token: 'tok' } : null,
                    error: null,
                  }),
              }),
              single: () => Promise.resolve({ data: { id: PAYMENT_ID }, error: null }),
            }),
          }),
          insert: (row: Record<string, unknown>) => {
            payments.push({ ...row, id: PAYMENT_ID });
            return {
              select: () => ({
                single: () => Promise.resolve({ data: { id: PAYMENT_ID }, error: null }),
              }),
            };
          },
          update: () => ({
            eq: () => Promise.resolve({ error: null }),
          }),
        };
      }
      if (table === 'rider_payment_methods') {
        return {
          select: () => ({
            eq: () => ({
              eq: () => ({
                maybeSingle: () => Promise.resolve({ data: null, error: null }),
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
      };
    },
    rpc: (name: string) => {
      if (name === 'trip_payable_total') {
        return Promise.resolve({ data: options?.tripPayableTotal ?? 850, error: null });
      }
      if (name === 'verify_payment_token') {
        return Promise.resolve({ data: null, error: { message: 'CANDIDATE_EXPIRED' } });
      }
      if (name === 'cfg') {
        return Promise.resolve({ data: name.includes('commission') ? 0.05 : 100, error: null });
      }
      return Promise.resolve({ data: null, error: null });
    },
    _payments: () => payments,
  };
}

Deno.test('TS-UI-04: payments/initiate with digital_enabled=false → STATE_INVALID, provider calls = 0', async () => {
  let providerCalls = 0;
  const body = paymentInitiateSchema.parse({ driver_code: DRIVER_CODE, trip_id: TRIP_ID, channel: 'app' });
  const service = createMockService();

  const res = await handlePaymentInitiate(body, {
    userClient: {} as never,
    service: service as never,
    riderId: RIDER_ID,
    provider: createMockProvider(() => {
      providerCalls += 1;
    }),
    cfgBool: async () => false,
    cfgNum: async () => 100,
    cfgText: async () => 'account',
  });

  assertEquals(res.status, 409);
  const json = await res.json();
  assertEquals(json.error.code, 'STATE_INVALID');
  assertEquals(providerCalls, 0);
});

Deno.test('TS-UI-04: payments/initiate with trip_id rejects client amount mismatch', async () => {
  let providerCalls = 0;
  const body = paymentInitiateSchema.parse({
    driver_code: DRIVER_CODE,
    trip_id: TRIP_ID,
    amount: 999,
    channel: 'app',
  });
  const service = createMockService();

  const res = await handlePaymentInitiate(body, {
    userClient: {} as never,
    service: service as never,
    riderId: RIDER_ID,
    provider: createMockProvider(() => {
      providerCalls += 1;
    }),
    cfgBool: async () => true,
    cfgNum: async () => 100,
    cfgText: async () => 'account',
  });

  assertEquals(res.status, 400);
  const json = await res.json();
  assertEquals(json.error.code, 'VALIDATION');
  assertEquals(providerCalls, 0);
});

Deno.test('TS-UI-04: payments/initiate stores server trip total and ignores omitted client amount', async () => {
  let providerCalls = 0;
  const body = paymentInitiateSchema.parse({ driver_code: DRIVER_CODE, trip_id: TRIP_ID, channel: 'app' });
  const service = createMockService();

  const res = await handlePaymentInitiate(body, {
    userClient: {} as never,
    service: service as never,
    riderId: RIDER_ID,
    provider: createMockProvider(() => {
      providerCalls += 1;
    }),
    cfgBool: async () => true,
    cfgNum: async (key) => (key === 'payments.initiate_ttl_s' ? 1800 : 100),
    cfgText: async () => 'account',
  });

  assertEquals(res.status, 200);
  const json = await res.json();
  assertEquals(json.data.amount, 850);
  assertEquals(json.data.payment_id, PAYMENT_ID);
  assertEquals(providerCalls, 1);

  const stored = (service as ReturnType<typeof createMockService> & {
    _payments: () => Record<string, unknown>[];
  })._payments();
  assertEquals(stored[0]?.amount, 850);
});

Deno.test('TS-QR-03: initiate without confirm_other_driver → VALIDATION', async () => {
  const body = paymentInitiateSchema.parse({
    driver_code: DRIVER_CODE,
    amount: 500,
    channel: 'app',
  });
  const service = createMockService({ otherActiveTrip: true });

  const res = await handlePaymentInitiate(body, {
    userClient: {} as never,
    service: service as never,
    riderId: RIDER_ID,
    provider: createMockProvider(),
    cfgBool: async () => true,
    cfgNum: async (key) => (key === 'payments.initiate_ttl_s' ? 1800 : 100),
    cfgText: async () => 'account',
  });

  assertEquals(res.status, 400);
  const json = await res.json();
  assertEquals(json.error.code, 'VALIDATION');
});

Deno.test('TS-QR-05: split amounts equal fare − commission to the kobo', async () => {
  let capturedParams: TripPaymentInitiateParams | undefined;
  const body = paymentInitiateSchema.parse({ driver_code: DRIVER_CODE, trip_id: TRIP_ID, channel: 'app' });
  const service = createMockService();

  const res = await handlePaymentInitiate(body, {
    userClient: {} as never,
    service: service as never,
    riderId: RIDER_ID,
    provider: createMockProvider((params) => {
      capturedParams = params;
    }),
    cfgBool: async () => true,
    cfgNum: async (key) => (key === 'payments.initiate_ttl_s' ? 1800 : 100),
    cfgText: async () => 'account',
  });

  assertEquals(res.status, 200);
  const json = await res.json();

  const amount = 850;
  const commission = 42.5;
  const driverAmount = 807.5;

  assertEquals(json.data.amount, amount);
  assertEquals(json.data.commission_amount, commission);
  assertEquals(json.data.driver_amount, driverAmount);

  const amountKobo = Math.round(amount * 100);
  const commissionKobo = Math.round(commission * 100);
  const driverKobo = Math.round(driverAmount * 100);

  assertEquals(amountKobo, commissionKobo + driverKobo);
  assertEquals(capturedParams?.amount, amount);
  assertEquals(capturedParams?.commissionAmount, commission);
  assertEquals(capturedParams?.driverSubaccountCode, 'ACCT_test_sub');
});

Deno.test('TS-QR-08: second initiate for paid trip returns CONFLICT with payment_id', async () => {
  const body = paymentInitiateSchema.parse({ driver_code: DRIVER_CODE, trip_id: TRIP_ID, channel: 'app' });
  const service = createMockService({ existingPaid: true });

  const res = await handlePaymentInitiate(body, {
    userClient: {} as never,
    service: service as never,
    riderId: RIDER_ID,
    provider: createMockProvider(),
    cfgBool: async () => true,
    cfgNum: async (key) => (key === 'payments.initiate_ttl_s' ? 1800 : 100),
    cfgText: async () => 'account',
  });

  assertEquals(res.status, 409);
  const json = await res.json();
  assertEquals(json.error.code, 'CONFLICT');
  assertEquals(json.error.details.payment_id, 'existing');
});

Deno.test('TS-QR-09: anonymous web initiate stores web_anonymous source', async () => {
  const body = paymentInitiateSchema.parse({
    driver_code: DRIVER_CODE,
    amount: 450,
    channel: 'web',
  });
  const service = createMockService();

  const res = await handlePaymentInitiate(body, {
    userClient: {} as never,
    service: service as never,
    riderId: null,
    provider: createMockProvider(),
    cfgBool: async () => true,
    cfgNum: async (key) => (key === 'payments.initiate_ttl_s' ? 1800 : 100),
    cfgText: async () => 'account',
  });

  assertEquals(res.status, 200);
  const stored = (service as ReturnType<typeof createMockService> & {
    _payments: () => Record<string, unknown>[];
  })._payments();
  assertEquals(stored[0]?.source, 'web_anonymous');
  assertEquals(stored[0]?.rider_id, null);
  assertEquals(stored[0]?.channel, 'web');
});
