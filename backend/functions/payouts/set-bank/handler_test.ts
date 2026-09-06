import { assertEquals } from 'jsr:@std/assert@1';
import type { PaymentProvider, TripPaymentInitiateParams } from '../../_shared/payments/mod.ts';
import {
  handleSetPayoutBank,
  setPayoutBankSchema,
} from './handler.ts';

const DRIVER_ID = '0f200000-0000-4000-8000-000000000050';
const ACCOUNT_NUMBER = '0123456789';

function createMockProvider(): PaymentProvider {
  return {
    initiateSettlement: () => Promise.reject(new Error('not used')),
    initiateTripPayment: () => Promise.reject(new Error('not used')),
    initiatePayoutTransfer: () => Promise.reject(new Error('not used')),
    resolveAccountName: () => Promise.resolve({ accountName: 'Test Driver Account' }),
    createSubaccount: () => Promise.resolve({ subaccountCode: 'ACCT_sub_test_001' }),
  };
}

function createMockClients(options?: { reauthOk?: boolean; isDriver?: boolean }) {
  const reauthOk = options?.reauthOk ?? true;
  const isDriver = options?.isDriver ?? true;

  const userClient = {
    rpc: (name: string) => {
      if (name === 'assert_payout_reauth') {
        if (!reauthOk) {
          return Promise.resolve({ data: null, error: { message: 'REAUTH_REQUIRED' } });
        }
        return Promise.resolve({ data: null, error: null });
      }
      if (name === 'persist_driver_payout_bank') {
        return Promise.resolve({
          data: {
            payout_subaccount_code: 'ACCT_sub_test_001',
            payout_bank_last4: '6789',
            driver_code: 'DRVTEST1',
          },
          error: null,
        });
      }
      return Promise.resolve({ data: null, error: { message: 'unexpected rpc' } });
    },
  };

  const service = {
    from: (table: string) => ({
      select: () => ({
        eq: () => ({
          maybeSingle: () =>
            Promise.resolve({
              data: isDriver ? { id: DRIVER_ID } : null,
              error: null,
            }),
          single: () =>
            Promise.resolve({
              data: { display_name: 'Test Driver' },
              error: null,
            }),
        }),
      }),
    }),
  };

  return { userClient, service };
}

Deno.test('payouts/set-bank: rejects without recent OTP re-auth', async () => {
  const body = setPayoutBankSchema.parse({ bank_code: '058', account_number: ACCOUNT_NUMBER });
  const { userClient, service } = createMockClients({ reauthOk: false });

  const res = await handleSetPayoutBank(body, {
    userClient: userClient as never,
    service: service as never,
    driverId: DRIVER_ID,
    driverDisplayName: 'Test Driver',
    provider: createMockProvider(),
  });

  assertEquals(res.status, 401);
  const json = await res.json();
  assertEquals(json.error.code, 'REAUTH_REQUIRED');
});

Deno.test('payouts/set-bank: persists subaccount code and last4 only', async () => {
  const body = setPayoutBankSchema.parse({ bank_code: '058', account_number: ACCOUNT_NUMBER });
  const { userClient, service } = createMockClients();

  const res = await handleSetPayoutBank(body, {
    userClient: userClient as never,
    service: service as never,
    driverId: DRIVER_ID,
    driverDisplayName: 'Test Driver',
    provider: createMockProvider(),
  });

  assertEquals(res.status, 200);
  const json = await res.json();
  assertEquals(json.data.payout_subaccount_code, 'ACCT_sub_test_001');
  assertEquals(json.data.payout_bank_last4, '6789');
  assertEquals(json.data.account_name, 'Test Driver Account');
});

Deno.test('payouts/set-bank: rejects non-driver', async () => {
  const body = setPayoutBankSchema.parse({ bank_code: '058', account_number: ACCOUNT_NUMBER });
  const { userClient, service } = createMockClients({ isDriver: false });

  const res = await handleSetPayoutBank(body, {
    userClient: userClient as never,
    service: service as never,
    driverId: DRIVER_ID,
    driverDisplayName: 'Test Driver',
    provider: createMockProvider(),
  });

  assertEquals(res.status, 403);
});
