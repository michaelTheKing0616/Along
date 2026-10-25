import { z } from 'zod';
import { jsonResponse, errorResponse, requestId } from '../../_shared/http.ts';
import {
  createPaystackProvider,
  type PaymentProvider,
} from '../../_shared/payments/mod.ts';
import { ngBankName } from '../../_shared/payments/ng_banks.ts';
import { createServiceClient, createUserClient } from '../../_shared/supabase.ts';
import type { SupabaseClient } from '@supabase/supabase-js';

export const setPayoutBankSchema = z.object({
  bank_code: z.string().min(1),
  account_number: z.string().regex(/^\d{10}$/, 'account_number must be 10 digits'),
});

export type SetPayoutBankRequest = z.infer<typeof setPayoutBankSchema>;

export type SetPayoutBankDeps = {
  userClient: SupabaseClient;
  service: SupabaseClient;
  provider: PaymentProvider;
  driverId: string;
  driverDisplayName: string;
};

function bankLast4(accountNumber: string): string {
  return accountNumber.slice(-4);
}

export async function handleSetPayoutBank(
  body: SetPayoutBankRequest,
  deps: SetPayoutBankDeps,
): Promise<Response> {
  const rid = requestId();

  const { data: driver, error: driverError } = await deps.service
    .from('drivers')
    .select('id')
    .eq('id', deps.driverId)
    .maybeSingle();

  if (driverError || !driver?.id) {
    return errorResponse('FORBIDDEN', 'Not a driver', 403, { request_id: rid });
  }

  const { error: reauthError } = await deps.userClient.rpc('assert_payout_reauth');
  if (reauthError) {
    const code = reauthError.message?.includes('REAUTH_REQUIRED') ? 'REAUTH_REQUIRED' : 'FORBIDDEN';
    const status = code === 'REAUTH_REQUIRED' ? 401 : 403;
    return errorResponse(code, 'Recent phone OTP verification required', status, {
      request_id: rid,
    });
  }

  let accountName: string;
  try {
    const resolved = await deps.provider.resolveAccountName({
      bankCode: body.bank_code,
      accountNumber: body.account_number,
    });
    accountName = resolved.accountName;
  } catch {
    return errorResponse('VALIDATION', 'Could not verify bank account', 400, { request_id: rid });
  }

  let subaccountCode: string;
  try {
    const created = await deps.provider.createSubaccount({
      businessName: accountName || deps.driverDisplayName,
      bankCode: body.bank_code,
      accountNumber: body.account_number,
      contactEmail: `${deps.driverId}@drivers.along.ng`,
    });
    subaccountCode = created.subaccountCode;
  } catch {
    return errorResponse('VALIDATION', 'Could not create payout subaccount', 400, {
      request_id: rid,
    });
  }

  const last4 = bankLast4(body.account_number);

  const { data: persisted, error: persistError } = await deps.userClient.rpc(
    'persist_driver_payout_bank',
    {
      p_subaccount_code: subaccountCode,
      p_bank_last4: last4,
      p_bank_name: ngBankName(body.bank_code),
    },
  );

  if (persistError) {
    const code = persistError.message?.includes('REAUTH_REQUIRED') ? 'REAUTH_REQUIRED' : 'VALIDATION';
    const status = code === 'REAUTH_REQUIRED' ? 401 : 400;
    return errorResponse(code, persistError.message ?? 'Persist failed', status, {
      request_id: rid,
    });
  }

  return jsonResponse({
    data: {
      payout_subaccount_code: subaccountCode,
      payout_bank_last4: last4,
      payout_bank_name: ngBankName(body.bank_code),
      driver_code: (persisted as { driver_code?: string })?.driver_code,
      account_name: accountName,
    },
    meta: { request_id: rid },
  });
}

export async function handleSetPayoutBankDefault(
  body: SetPayoutBankRequest,
  authHeader: string,
): Promise<Response> {
  const userClient = createUserClient(authHeader);
  const { data: userData, error: userError } = await userClient.auth.getUser();
  if (userError || !userData.user?.id) {
    return errorResponse('UNAUTHENTICATED', 'Invalid session', 401, {
      request_id: requestId(),
    });
  }

  const service = createServiceClient();
  const secret = Deno.env.get('PAYSTACK_SECRET_KEY');
  if (!secret) {
    throw new Error('PAYSTACK_SECRET_KEY not configured');
  }

  const { data: profile } = await service
    .from('profiles')
    .select('display_name')
    .eq('id', userData.user.id)
    .single();

  return handleSetPayoutBank(body, {
    userClient,
    service,
    driverId: userData.user.id,
    driverDisplayName: (profile?.display_name as string | null) ?? 'Along Driver',
    provider: createPaystackProvider(secret),
  });
}
