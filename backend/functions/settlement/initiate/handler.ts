import { z } from 'zod';
import { jsonResponse, errorResponse, requestId } from '../../_shared/http.ts';
import {
  createPaystackProvider,
  type PaymentProvider,
  type SettlementChannel,
} from '../../_shared/payments/mod.ts';
import { createServiceClient, createUserClient } from '../../_shared/supabase.ts';
import type { SupabaseClient } from '@supabase/supabase-js';

export const settlementInitiateSchema = z.object({
  amount: z.number().positive(),
  channel: z.enum(['paystack_transfer', 'paystack_ussd', 'paystack_card']),
});

export type SettlementInitiateRequest = z.infer<typeof settlementInitiateSchema>;

export type SettlementInitiateDeps = {
  userClient: SupabaseClient;
  service: SupabaseClient;
  provider: PaymentProvider;
  driverId: string;
  cfgInitiateTtlMin: (cityId: string) => Promise<number>;
};

async function driverCityAndCurrency(
  service: SupabaseClient,
  driverId: string,
): Promise<{ cityId: string; currency: string }> {
  const { data: driver, error: driverError } = await service
    .from('drivers')
    .select('city_id')
    .eq('id', driverId)
    .single();

  if (driverError || !driver?.city_id) {
    throw new Error('NOT_FOUND');
  }

  const { data: city, error: cityError } = await service
    .from('cities')
    .select('country_code')
    .eq('id', driver.city_id)
    .single();

  if (cityError || !city?.country_code) {
    throw new Error('NOT_FOUND');
  }

  const { data: country, error: countryError } = await service
    .from('countries')
    .select('currency_code')
    .eq('code', city.country_code)
    .single();

  if (countryError || !country?.currency_code) {
    throw new Error('NOT_FOUND');
  }

  return { cityId: driver.city_id as string, currency: country.currency_code as string };
}

export async function handleSettlementInitiate(
  body: SettlementInitiateRequest,
  deps: SettlementInitiateDeps,
): Promise<Response> {
  const rid = requestId();
  const { cityId, currency } = await driverCityAndCurrency(deps.service, deps.driverId);
  const ttlMin = await deps.cfgInitiateTtlMin(cityId);
  const expiresAt = new Date(Date.now() + ttlMin * 60 * 1000).toISOString();

  const { data: settlement, error: insertError } = await deps.service
    .from('settlements')
    .insert({
      driver_id: deps.driverId,
      amount: body.amount,
      currency,
      channel: body.channel as SettlementChannel,
      status: 'pending',
      expires_at: expiresAt,
    })
    .select('id')
    .single();

  if (insertError || !settlement?.id) {
    throw new Error(insertError?.message ?? 'settlement insert failed');
  }

  const providerResult = await deps.provider.initiateSettlement({
    settlementId: settlement.id,
    amount: body.amount,
    currency,
    channel: body.channel,
    driverId: deps.driverId,
  });

  const { error: updateError } = await deps.service
    .from('settlements')
    .update({
      provider_reference: providerResult.providerReference,
      expires_at: providerResult.expiresAt ?? expiresAt,
    })
    .eq('id', settlement.id);

  if (updateError) {
    throw new Error(updateError.message);
  }

  const data: Record<string, unknown> = {
    settlement_id: settlement.id,
    expires_at: providerResult.expiresAt ?? expiresAt,
  };
  if (providerResult.authorizationUrl) data.authorization_url = providerResult.authorizationUrl;
  if (providerResult.ussdCode) data.ussd_code = providerResult.ussdCode;
  if (providerResult.bankAccount) data.bank_account = providerResult.bankAccount;

  return jsonResponse({ data, meta: { request_id: rid } });
}

export async function handleSettlementInitiateDefault(
  body: SettlementInitiateRequest,
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

  return handleSettlementInitiate(body, {
    userClient,
    service,
    driverId: userData.user.id,
    provider: createPaystackProvider(secret),
    cfgInitiateTtlMin: async (cityId) => {
      const { data, error } = await service.rpc('cfg_num', {
        p_key: 'settlement.initiate_ttl_min',
        p_city: cityId,
      });
      if (error) throw error;
      return Number(data ?? 30);
    },
  });
}
