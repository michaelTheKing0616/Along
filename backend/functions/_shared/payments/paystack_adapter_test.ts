import { assertEquals } from 'jsr:@std/assert@1';
import { createPaystackProvider } from './paystack_adapter.ts';
import type { TripPaymentInitiateParams } from './types.ts';

const PARAMS: TripPaymentInitiateParams = {
  paymentId: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
  amount: 450,
  commissionAmount: 33.75,
  currency: 'NGN',
  method: 'bank_transfer',
  driverSubaccountCode: 'ACCT_test',
  feeBearer: 'account',
  riderEmail: 'rider@along.ng',
};

Deno.test('bank_transfer uses /charge and returns virtual account', async () => {
  let url = '';
  let body: Record<string, unknown> = {};
  // deno-lint-ignore require-await -- test double satisfies an async interface
  const provider = createPaystackProvider('sk_test', async (input, init) => {
    url = String(input);
    body = JSON.parse(String(init?.body ?? '{}')) as Record<string, unknown>;
    return new Response(
      JSON.stringify({
        status: true,
        data: {
          reference: 'ref_va_1',
          account_number: '1234567890',
          account_name: 'PAYSTACK CHECKOUT',
          bank: { name: 'Test Bank' },
          account_expires_at: '2026-09-09T10:00:00.000Z',
        },
      }),
      { status: 200 },
    );
  });

  const result = await provider.initiateTripPayment(PARAMS);
  assertEquals(url, 'https://api.paystack.co/charge');
  assertEquals((body.bank_transfer as { account_expires_at: string }).account_expires_at.length > 0, true);
  assertEquals(body.subaccount, 'ACCT_test');
  assertEquals(body.amount, 45000);
  assertEquals(result.providerReference, 'ref_va_1');
  assertEquals(result.bankAccount?.account_number, '1234567890');
  assertEquals(result.bankAccount?.bank_name, 'Test Bank');
  assertEquals(result.authorizationUrl, undefined);
});

Deno.test('card still uses transaction/initialize', async () => {
  let url = '';
  // deno-lint-ignore require-await -- test double satisfies an async interface
  const provider = createPaystackProvider('sk_test', async (input) => {
    url = String(input);
    return new Response(
      JSON.stringify({
        status: true,
        data: {
          reference: 'ref_card_1',
          authorization_url: 'https://checkout.paystack.com/x',
        },
      }),
      { status: 200 },
    );
  });

  const result = await provider.initiateTripPayment({ ...PARAMS, method: 'card' });
  assertEquals(url, 'https://api.paystack.co/transaction/initialize');
  assertEquals(result.authorizationUrl, 'https://checkout.paystack.com/x');
});
