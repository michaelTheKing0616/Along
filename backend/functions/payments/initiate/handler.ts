import { z } from 'zod';
import { jsonResponse, errorResponse, requestId } from '../../_shared/http.ts';
import {
  createPaystackProvider,
  type PaymentMethodPref,
  type PaymentProvider,
} from '../../_shared/payments/mod.ts';
import { createServiceClient, createUserClient } from '../../_shared/supabase.ts';
import type { SupabaseClient } from '@supabase/supabase-js';

export const paymentInitiateSchema = z.object({
  trip_id: z.string().uuid(),
  amount: z.number().positive().optional(),
  channel: z.enum(['app', 'web']).default('app'),
  method_pref: z.enum(['card', 'bank_transfer', 'ussd']).default('card'),
});

export type PaymentInitiateRequest = z.input<typeof paymentInitiateSchema>;
export type PaymentInitiateBody = z.infer<typeof paymentInitiateSchema>;

type TripRow = {
  id: string;
  rider_id: string;
  driver_id: string;
  fare_shown: number;
  load_surcharge_amount: number;
  fare_currency: string;
  commission_rate: number;
  commission_amount: number | null;
  status: string;
  payment_method: string;
};

type DriverRow = {
  id: string;
  city_id: string;
  payout_subaccount_code: string | null;
  accepts_digital: boolean;
};

export type PaymentInitiateDeps = {
  userClient: SupabaseClient;
  service: SupabaseClient;
  provider: PaymentProvider;
  riderId: string;
  cfgBool: (key: string, cityId: string) => Promise<boolean>;
  cfgNum: (key: string, cityId: string) => Promise<number>;
  cfgText: (key: string, cityId: string) => Promise<string>;
};

function roundMoney(value: number): number {
  return Math.round(value * 100) / 100;
}

export async function handlePaymentInitiate(
  body: PaymentInitiateBody,
  deps: PaymentInitiateDeps,
): Promise<Response> {
  const rid = requestId();

  const { data: trip, error: tripError } = await deps.service
    .from('trips')
    .select(
      'id, rider_id, driver_id, fare_shown, load_surcharge_amount, fare_currency, commission_rate, commission_amount, status, payment_method',
    )
    .eq('id', body.trip_id)
    .single();

  if (tripError || !trip) {
    return errorResponse('NOT_FOUND', 'Trip not found', 404, { request_id: rid });
  }

  const t = trip as TripRow;

  if (t.rider_id !== deps.riderId) {
    return errorResponse('FORBIDDEN', 'Not your trip', 403, { request_id: rid });
  }

  const { data: driver, error: driverError } = await deps.service
    .from('drivers')
    .select('id, city_id, payout_subaccount_code, accepts_digital')
    .eq('id', t.driver_id)
    .single();

  if (driverError || !driver) {
    return errorResponse('NOT_FOUND', 'Driver not found', 404, { request_id: rid });
  }

  const d = driver as DriverRow;
  const serverAmount = roundMoney(t.fare_shown + (t.load_surcharge_amount ?? 0));

  const digitalEnabled = await deps.cfgBool('payments.digital_enabled', d.city_id);
  if (!digitalEnabled) {
    return errorResponse('STATE_INVALID', 'Digital payments are not enabled', 409, {
      request_id: rid,
    });
  }

  if (body.amount !== undefined && roundMoney(body.amount) !== serverAmount) {
    return errorResponse('VALIDATION', 'Amount must match trip total', 400, { request_id: rid });
  }

  const minAmount = await deps.cfgNum('payments.min_digital_amount', d.city_id);
  if (serverAmount < minAmount) {
    return errorResponse('VALIDATION', `Amount below minimum (${minAmount})`, 400, {
      request_id: rid,
    });
  }

  if (!d.payout_subaccount_code || !d.accepts_digital) {
    return errorResponse('STATE_INVALID', 'Driver cannot accept digital payments', 409, {
      request_id: rid,
    });
  }

  const { data: existingPaid } = await deps.service
    .from('payments')
    .select('id')
    .eq('trip_id', body.trip_id)
    .eq('status', 'succeeded')
    .maybeSingle();

  if (existingPaid?.id) {
    return errorResponse('CONFLICT', 'Trip already paid', 409, {
      request_id: rid,
    });
  }

  const commission = roundMoney(
    t.commission_amount ?? serverAmount * t.commission_rate,
  );
  const driverAmount = roundMoney(serverAmount - commission);
  const feeBearer = await deps.cfgText('payments.fee_bearer', d.city_id);
  const normalizedBearer = feeBearer.replace(/^"|"$/g, '') as 'account' | 'subaccount';

  const { data: payment, error: insertError } = await deps.service
    .from('payments')
    .insert({
      driver_id: t.driver_id,
      trip_id: body.trip_id,
      rider_id: deps.riderId,
      source: 'app_trip',
      channel: body.channel,
      amount: serverAmount,
      currency: t.fare_currency,
      commission_amount: commission,
      driver_amount: driverAmount,
      fee_bearer: normalizedBearer,
      provider: 'paystack',
      provider_reference: `pending_${crypto.randomUUID()}`,
      method: body.method_pref,
      status: 'initiated',
    })
    .select('id')
    .single();

  if (insertError || !payment?.id) {
    throw new Error(insertError?.message ?? 'payment insert failed');
  }

  const providerResult = await deps.provider.initiateTripPayment({
    paymentId: payment.id as string,
    amount: serverAmount,
    commissionAmount: commission,
    currency: t.fare_currency,
    method: body.method_pref as PaymentMethodPref,
    driverSubaccountCode: d.payout_subaccount_code,
    feeBearer: normalizedBearer,
  });

  const { error: updateError } = await deps.service
    .from('payments')
    .update({
      provider_reference: providerResult.providerReference,
      status: 'pending',
    })
    .eq('id', payment.id);

  if (updateError) {
    throw new Error(updateError.message);
  }

  const data: Record<string, unknown> = {
    payment_id: payment.id,
    amount: serverAmount,
    commission_amount: commission,
    driver_amount: driverAmount,
    expires_at: providerResult.expiresAt,
  };
  if (providerResult.authorizationUrl) data.authorization_url = providerResult.authorizationUrl;
  if (providerResult.ussdCode) data.ussd_code = providerResult.ussdCode;
  if (providerResult.bankAccount) data.transfer_account = providerResult.bankAccount;

  return jsonResponse({ data, meta: { request_id: rid } });
}

export async function handlePaymentInitiateDefault(
  body: PaymentInitiateRequest,
  authHeader: string,
): Promise<Response> {
  const parsed = paymentInitiateSchema.parse(body);
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

  const cfgRpc = async (key: string, cityId: string) => {
    const { data, error } = await service.rpc('cfg', { p_key: key, p_city: cityId });
    if (error) throw error;
    return data;
  };

  return handlePaymentInitiate(parsed, {
    userClient,
    service,
    riderId: userData.user.id,
    provider: createPaystackProvider(secret),
    cfgBool: async (key, cityId) => {
      const raw = await cfgRpc(key, cityId);
      return raw === true || raw === 'true';
    },
    cfgNum: async (key, cityId) => Number(await cfgRpc(key, cityId)),
    cfgText: async (key, cityId) => String(await cfgRpc(key, cityId)),
  });
}
