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
  driver_code: z.string().min(1),
  trip_id: z.string().uuid().optional(),
  amount: z.number().positive().optional(),
  token: z.string().optional(),
  method_pref: z.enum(['card', 'bank_transfer', 'ussd', 'saved']).default('bank_transfer'),
  channel: z.enum(['app', 'web']).default('app'),
  payer_phone: z.string().optional(),
  confirm_other_driver: z.boolean().optional(),
  payment_method_id: z.string().uuid().optional(),
});

export type PaymentInitiateRequest = z.input<typeof paymentInitiateSchema>;
export type PaymentInitiateBody = z.infer<typeof paymentInitiateSchema>;

type DriverRow = {
  id: string;
  city_id: string;
  payout_subaccount_code: string | null;
  accepts_digital: boolean;
  driver_code: string;
};

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

export type PaymentInitiateDeps = {
  userClient: SupabaseClient;
  service: SupabaseClient;
  provider: PaymentProvider;
  riderId: string | null;
  cfgBool: (key: string, cityId: string) => Promise<boolean>;
  cfgNum: (key: string, cityId: string) => Promise<number>;
  cfgText: (key: string, cityId: string) => Promise<string>;
};

function roundMoney(value: number): number {
  return Math.round(value * 100) / 100;
}

function mapRpcError(message: string, rid: string): Response {
  const upper = message.toUpperCase();
  if (upper.includes('NOT_FOUND')) {
    return errorResponse('NOT_FOUND', 'Not found', 404, { request_id: rid });
  }
  if (upper.includes('FORBIDDEN')) {
    return errorResponse('FORBIDDEN', 'Forbidden', 403, { request_id: rid });
  }
  if (upper.includes('CONFLICT')) {
    return errorResponse('CONFLICT', 'Already paid', 409, { request_id: rid });
  }
  if (upper.includes('CANDIDATE_EXPIRED')) {
    return errorResponse('CANDIDATE_EXPIRED', 'Token expired or invalid', 410, { request_id: rid });
  }
  if (upper.includes('STATE_INVALID')) {
    return errorResponse('STATE_INVALID', message, 409, { request_id: rid });
  }
  if (upper.includes('VALIDATION')) {
    return errorResponse('VALIDATION', message, 400, { request_id: rid });
  }
  if (upper.includes('UNAUTHENTICATED')) {
    return errorResponse('UNAUTHENTICATED', 'Authentication required', 401, { request_id: rid });
  }
  return errorResponse('VALIDATION', message, 400, { request_id: rid });
}

async function deriveAmount(
  service: SupabaseClient,
  body: PaymentInitiateBody,
  driver: DriverRow,
  riderId: string | null,
): Promise<{ amount: number; tripId: string | null; source: string; currency: string; commissionRate: number; commissionAmount: number | null }> {
  let amount: number | undefined;
  let tripId: string | null = body.trip_id ?? null;
  let source = 'qr_static';
  let currency = 'NGN';
  let commissionRate: number | undefined;
  let commissionAmount: number | null = null;

  if (body.token) {
    const { data: tokenRows, error: tokenError } = await service.rpc('verify_payment_token', {
      p_token: body.token,
      p_city_id: driver.city_id,
    });
    if (tokenError) throw tokenError;
    const row = (tokenRows as { trip_id: string; driver_id: string; amount: number }[] | null)?.[0];
    if (!row) {
      throw new Error('CANDIDATE_EXPIRED');
    }
    if (row.driver_id !== driver.id) {
      throw new Error('FORBIDDEN');
    }
    tripId = row.trip_id;
    amount = roundMoney(Number(row.amount));
    source = 'qr_dynamic';
  }

  if (tripId) {
    const { data: trip, error: tripError } = await service
      .from('trips')
      .select(
        'id, rider_id, driver_id, fare_shown, load_surcharge_amount, fare_currency, commission_rate, commission_amount, status, payment_method',
      )
      .eq('id', tripId)
      .single();

    if (tripError || !trip) {
      throw new Error('NOT_FOUND');
    }

    const t = trip as TripRow;
    if (t.driver_id !== driver.id) {
      throw new Error('FORBIDDEN');
    }

    const { data: serverTotal, error: totalError } = await service.rpc('trip_payable_total', {
      p_trip_id: tripId,
    });
    if (totalError) throw totalError;

    const serverAmount = roundMoney(Number(serverTotal));
    if (amount !== undefined && roundMoney(amount) !== serverAmount) {
      throw new Error('VALIDATION: amount must match trip total');
    }
    if (body.amount !== undefined && roundMoney(body.amount) !== serverAmount) {
      throw new Error('VALIDATION: amount must match trip total');
    }

    amount = serverAmount;
    currency = t.fare_currency;
    commissionRate = t.commission_rate;
    commissionAmount = t.commission_amount;
    if (body.token) {
      source = 'qr_dynamic';
    } else if (body.channel === 'app' && riderId && t.rider_id === riderId) {
      source = 'app_trip';
    } else {
      source = 'qr_static';
    }

    return { amount, tripId, source, currency, commissionRate, commissionAmount };
  }

  if (body.amount === undefined) {
    throw new Error('VALIDATION: amount required for unattributed payment');
  }

  amount = roundMoney(body.amount);
  const { data: countryRow } = await service
    .from('cities')
    .select('countries(currency_code)')
    .eq('id', driver.city_id)
    .single();
  const joined = countryRow as { countries?: { currency_code?: string } | null } | null;
  currency = joined?.countries?.currency_code ?? currency;
  const { data: rate } = await service.rpc('cfg', { p_key: 'commission.rate', p_city: driver.city_id });
  commissionRate = Number(rate);

  if (body.channel === 'web') {
    source = 'web_anonymous';
  }

  return { amount, tripId: null, source, currency, commissionRate, commissionAmount };
}

async function checkDifferentDriverWarning(
  service: SupabaseClient,
  riderId: string,
  driverId: string,
  confirm: boolean | undefined,
): Promise<void> {
  const { data: otherTrip } = await service
    .from('trips')
    .select('id')
    .eq('rider_id', riderId)
    .in('status', ['accepted', 'boarded', 'in_transit'])
    .neq('driver_id', driverId)
    .limit(1)
    .maybeSingle();

  if (otherTrip?.id && !confirm) {
    throw new Error('VALIDATION: confirm_other_driver required');
  }
}

export async function handlePaymentInitiate(
  body: PaymentInitiateBody,
  deps: PaymentInitiateDeps,
): Promise<Response> {
  const rid = requestId();

  const { data: driver, error: driverError } = await deps.service
    .from('drivers')
    .select('id, city_id, payout_subaccount_code, accepts_digital, driver_code')
    .eq('driver_code', body.driver_code)
    .single();

  if (driverError || !driver) {
    return errorResponse('NOT_FOUND', 'Driver not found', 404, { request_id: rid });
  }

  const d = driver as DriverRow;

  const digitalEnabled = await deps.cfgBool('payments.digital_enabled', d.city_id);
  if (!digitalEnabled) {
    return errorResponse('STATE_INVALID', 'Digital payments are not enabled', 409, {
      request_id: rid,
    });
  }

  if (!d.payout_subaccount_code || !d.accepts_digital) {
    return errorResponse('STATE_INVALID', 'Driver cannot accept digital payments', 409, {
      request_id: rid,
    });
  }

  if (body.channel === 'app' && !deps.riderId) {
    return errorResponse('UNAUTHENTICATED', 'Authentication required', 401, { request_id: rid });
  }

  let derived: Awaited<ReturnType<typeof deriveAmount>>;
  try {
    derived = await deriveAmount(deps.service, body, d, deps.riderId);
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Validation failed';
    return mapRpcError(message, rid);
  }

  const minAmount = await deps.cfgNum('payments.min_digital_amount', d.city_id);
  if (derived.amount < minAmount) {
    return errorResponse('VALIDATION', `Amount below minimum (${minAmount})`, 400, {
      request_id: rid,
    });
  }

  if (deps.riderId && derived.tripId) {
    const { data: trip } = await deps.service
      .from('trips')
      .select('rider_id')
      .eq('id', derived.tripId)
      .single();
    if (trip && (trip as { rider_id: string }).rider_id !== deps.riderId) {
      return errorResponse('FORBIDDEN', 'Not your trip', 403, { request_id: rid });
    }
  }

  if (deps.riderId) {
    try {
      await checkDifferentDriverWarning(deps.service, deps.riderId, d.id, body.confirm_other_driver);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Validation failed';
      return mapRpcError(message, rid);
    }
  }

  if (derived.tripId) {
    const { data: existingPaid } = await deps.service
      .from('payments')
      .select('id, receipt_token')
      .eq('trip_id', derived.tripId)
      .eq('status', 'succeeded')
      .maybeSingle();

    if (existingPaid?.id) {
      return errorResponse('CONFLICT', 'Trip already paid', 409, {
        request_id: rid,
      }, { payment_id: existingPaid.id as string });
    }
  }

  const commission = roundMoney(
    derived.commissionAmount ?? derived.amount * (derived.commissionRate ?? 0.075),
  );
  const driverAmount = roundMoney(derived.amount - commission);
  const feeBearer = await deps.cfgText('payments.fee_bearer', d.city_id);
  const normalizedBearer = feeBearer.replace(/^"|"$/g, '') as 'account' | 'subaccount';
  const ttlS = await deps.cfgNum('payments.initiate_ttl_s', d.city_id);
  const expiresAt = new Date(Date.now() + ttlS * 1000).toISOString();
  const receiptToken = crypto.randomUUID().replace(/-/g, '');

  const methodPref = body.method_pref === 'saved' ? 'card' : body.method_pref;

  const { data: payment, error: insertError } = await deps.service
    .from('payments')
    .insert({
      driver_id: d.id,
      trip_id: derived.tripId,
      rider_id: deps.riderId,
      source: derived.source,
      channel: body.channel,
      amount: derived.amount,
      currency: derived.currency,
      commission_amount: commission,
      driver_amount: driverAmount,
      fee_bearer: normalizedBearer,
      provider: 'paystack',
      provider_reference: `pending_${crypto.randomUUID()}`,
      method: methodPref,
      status: 'initiated',
      payer_phone_e164: body.payer_phone ?? null,
      expires_at: expiresAt,
      receipt_token: receiptToken,
    })
    .select('id')
    .single();

  if (insertError || !payment?.id) {
    if (insertError?.code === '23505') {
      return errorResponse('CONFLICT', 'Trip already paid', 409, { request_id: rid });
    }
    throw new Error(insertError?.message ?? 'payment insert failed');
  }

  let providerResult;
  if (body.method_pref === 'saved' && deps.riderId) {
    const methodId = body.payment_method_id;
    let query = deps.service
      .from('rider_payment_methods')
      .select('authorization_code')
      .eq('rider_id', deps.riderId);
    if (methodId) {
      query = query.eq('id', methodId);
    } else {
      query = query.eq('is_default', true);
    }
    const { data: methodRow, error: methodError } = await query.maybeSingle();
    if (methodError || !methodRow?.authorization_code) {
      return errorResponse('STATE_INVALID', 'No saved payment method', 409, { request_id: rid });
    }

    providerResult = await deps.provider.chargeAuthorization({
      paymentId: payment.id as string,
      amount: derived.amount,
      commissionAmount: commission,
      currency: derived.currency,
      authorizationCode: methodRow.authorization_code as string,
      driverSubaccountCode: d.payout_subaccount_code,
      feeBearer: normalizedBearer,
      riderEmail: deps.riderId ? `${deps.riderId}@riders.along.ng` : undefined,
    });
  } else {
    providerResult = await deps.provider.initiateTripPayment({
      paymentId: payment.id as string,
      amount: derived.amount,
      commissionAmount: commission,
      currency: derived.currency,
      method: methodPref as PaymentMethodPref,
      driverSubaccountCode: d.payout_subaccount_code,
      feeBearer: normalizedBearer,
      riderEmail: deps.riderId ? `${deps.riderId}@riders.along.ng` : undefined,
    });
  }

  const { error: updateError } = await deps.service
    .from('payments')
    .update({
      provider_reference: providerResult.providerReference,
      status: providerResult.status ?? 'pending',
    })
    .eq('id', payment.id);

  if (updateError) {
    throw new Error(updateError.message);
  }

  const data: Record<string, unknown> = {
    payment_id: payment.id,
    amount: derived.amount,
    commission_amount: commission,
    driver_amount: driverAmount,
    expires_at: providerResult.expiresAt ?? expiresAt,
  };
  if (providerResult.authorizationUrl) data.authorization_url = providerResult.authorizationUrl;
  if (providerResult.ussdCode) data.ussd_code = providerResult.ussdCode;
  if (providerResult.bankAccount) data.transfer_account = providerResult.bankAccount;
  if (body.channel === 'web') data.receipt_token = receiptToken;

  return jsonResponse({ data, meta: { request_id: rid } });
}

export async function handlePaymentInitiateDefault(
  body: PaymentInitiateRequest,
  authHeader: string | null,
): Promise<Response> {
  const parsed = paymentInitiateSchema.parse(body);
  let riderId: string | null = null;
  let userClient: SupabaseClient | null = null;

  if (authHeader?.startsWith('Bearer ')) {
    userClient = createUserClient(authHeader);
    const { data: userData, error: userError } = await userClient.auth.getUser();
    if (userError || !userData.user?.id) {
      if (parsed.channel !== 'web') {
        return errorResponse('UNAUTHENTICATED', 'Invalid session', 401, {
          request_id: requestId(),
        });
      }
    } else {
      riderId = userData.user.id;
    }
  } else if (parsed.channel !== 'web') {
    return errorResponse('UNAUTHENTICATED', 'Missing authorization header', 401, {
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
    userClient: userClient ?? createServiceClient(),
    service,
    riderId,
    provider: createPaystackProvider(secret),
    cfgBool: async (key, cityId) => {
      const raw = await cfgRpc(key, cityId);
      return raw === true || raw === 'true';
    },
    cfgNum: async (key, cityId) => Number(await cfgRpc(key, cityId)),
    cfgText: async (key, cityId) => String(await cfgRpc(key, cityId)),
  });
}
