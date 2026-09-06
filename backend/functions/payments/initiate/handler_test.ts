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
    initiatePayoutTransfer: () => Promise.reject(new Error('not used')),
    resolveAccountName: () => Promise.reject(new Error('not used')),
    createSubaccount: () => Promise.reject(new Error('not used')),
  };
}

function createMockService(options?: {
  digitalEnabled?: boolean;
  existingPaid?: boolean;
  driverRow?: {
    id: string;
    city_id: string;
    payout_subaccount_code: string | null;
    accepts_digital: boolean;
  };
}) {
  const payments: Record<string, unknown>[] = [];
  const digitalEnabled = options?.digitalEnabled ?? true;
  const driverRow = options?.driverRow ?? DRIVER_ROW;

  return {
    from: (table: string) => {
      if (table === 'trips') {
        return {
          select: () => ({
            eq: () => ({
              single: () => Promise.resolve({ data: TRIP_ROW, error: null }),
            }),
          }),
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
                    data: options?.existingPaid ? { id: 'existing' } : null,
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
      return {
        select: () => ({
          eq: () => ({
            single: () => Promise.resolve({ data: null, error: { message: 'unexpected' } }),
          }),
        }),
      };
    },
    _payments: () => payments,
    _digitalEnabled: () => digitalEnabled,
  };
}

Deno.test('TS-UI-04: payments/initiate with digital_enabled=false → STATE_INVALID, provider calls = 0', async () => {
  let providerCalls = 0;
  const body = paymentInitiateSchema.parse({ trip_id: TRIP_ID, channel: 'app' });
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
  const body = paymentInitiateSchema.parse({ trip_id: TRIP_ID, channel: 'app' });
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

Deno.test('TS-UI-04: payments/initiate accepts matching client amount equal to server total', async () => {
  let providerCalls = 0;
  const body = paymentInitiateSchema.parse({ trip_id: TRIP_ID, amount: 850, channel: 'app' });
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

  assertEquals(res.status, 200);
  assertEquals(providerCalls, 1);
});

Deno.test('P4-A-08: driver without subaccount → STATE_INVALID, zero provider calls', async () => {
  let providerCalls = 0;
  const body = paymentInitiateSchema.parse({ trip_id: TRIP_ID, channel: 'app' });
  const service = createMockService({
    driverRow: { ...DRIVER_ROW, payout_subaccount_code: null },
  });

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

  assertEquals(res.status, 409);
  const json = await res.json();
  assertEquals(json.error.code, 'STATE_INVALID');
  assertEquals(providerCalls, 0);
});

Deno.test('P4-A-08: split amounts equal fare − commission to the kobo', async () => {
  let capturedParams: TripPaymentInitiateParams | undefined;
  const body = paymentInitiateSchema.parse({ trip_id: TRIP_ID, channel: 'app' });
  const service = createMockService();

  const res = await handlePaymentInitiate(body, {
    userClient: {} as never,
    service: service as never,
    riderId: RIDER_ID,
    provider: createMockProvider((params) => {
      capturedParams = params;
    }),
    cfgBool: async () => true,
    cfgNum: async () => 100,
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
  assertEquals(Math.round((capturedParams?.commissionAmount ?? 0) * 100), commissionKobo);

  const stored = (service as ReturnType<typeof createMockService> & {
    _payments: () => Record<string, unknown>[];
  })._payments();
  assertEquals(stored[0]?.amount, amount);
  assertEquals(stored[0]?.commission_amount, commission);
  assertEquals(stored[0]?.driver_amount, driverAmount);
});
