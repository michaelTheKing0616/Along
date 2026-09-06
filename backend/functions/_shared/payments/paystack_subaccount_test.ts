import { assertEquals } from 'jsr:@std/assert@1';
import { createPaystackProvider } from './paystack_adapter.ts';

Deno.test('paystack resolveAccountName calls bank/resolve endpoint', async () => {
  let capturedUrl = '';
  let capturedBody: Record<string, unknown> = {};

  const fetchImpl = (input: RequestInfo | URL, init?: RequestInit) => {
    capturedUrl = typeof input === 'string' ? input : input.toString();
    capturedBody = JSON.parse(String(init?.body));
    return Promise.resolve(
      new Response(
        JSON.stringify({ status: true, data: { account_name: 'Jane Driver' } }),
        { status: 200 },
      ),
    );
  };

  const provider = createPaystackProvider('sk_test', fetchImpl);
  const result = await provider.resolveAccountName({
    bankCode: '058',
    accountNumber: '0123456789',
  });

  assertEquals(result.accountName, 'Jane Driver');
  assertEquals(capturedUrl, 'https://api.paystack.co/bank/resolve');
  assertEquals(capturedBody.bank_code, '058');
  assertEquals(capturedBody.account_number, '0123456789');
});

Deno.test('paystack createSubaccount calls subaccount endpoint with zero percentage_charge', async () => {
  let capturedBody: Record<string, unknown> = {};

  const fetchImpl = (_input: RequestInfo | URL, init?: RequestInit) => {
    capturedBody = JSON.parse(String(init?.body));
    return Promise.resolve(
      new Response(
        JSON.stringify({ status: true, data: { subaccount_code: 'ACCT_test123' } }),
        { status: 200 },
      ),
    );
  };

  const provider = createPaystackProvider('sk_test', fetchImpl);
  const result = await provider.createSubaccount({
    businessName: 'Jane Driver',
    bankCode: '058',
    accountNumber: '0123456789',
    contactEmail: 'jane@drivers.along.ng',
  });

  assertEquals(result.subaccountCode, 'ACCT_test123');
  assertEquals(capturedBody.percentage_charge, 0);
  assertEquals(capturedBody.settlement_bank, '058');
});
