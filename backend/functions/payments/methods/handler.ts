import { z } from 'zod';
import { corsHeaders, errorResponse, jsonResponse, requestId } from '../../_shared/http.ts';
import { createServiceClient, createUserClient } from '../../_shared/supabase.ts';
import type { SupabaseClient } from '@supabase/supabase-js';

export const paymentsMethodsSchema = z.discriminatedUnion('action', [
  z.object({
    action: z.literal('list'),
  }),
  z.object({
    action: z.literal('add'),
    authorization_code: z.string().min(1),
    brand: z.string().optional(),
    last4: z.string().max(4).optional(),
    exp_month: z.number().int().min(1).max(12).optional(),
    exp_year: z.number().int().optional(),
    bank: z.string().optional(),
    set_default: z.boolean().optional(),
  }),
  z.object({
    action: z.literal('remove'),
    payment_method_id: z.string().uuid(),
  }),
  z.object({
    action: z.literal('default'),
    payment_method_id: z.string().uuid(),
  }),
]);

export type PaymentsMethodsBody = z.infer<typeof paymentsMethodsSchema>;

export async function handlePaymentsMethods(
  body: PaymentsMethodsBody,
  service: SupabaseClient,
  riderId: string,
): Promise<Response> {
  const rid = requestId();

  if (body.action === 'list') {
    // fall through to list query below
  } else if (body.action === 'add') {
    const { error } = await service.rpc('upsert_rider_payment_method', {
      p_authorization_code: body.authorization_code,
      p_brand: body.brand ?? null,
      p_last4: body.last4 ?? null,
      p_exp_month: body.exp_month ?? null,
      p_exp_year: body.exp_year ?? null,
      p_bank: body.bank ?? null,
      p_set_default: body.set_default ?? true,
    });
    if (error) {
      return errorResponse('VALIDATION', error.message, 400, { request_id: rid });
    }
  } else if (body.action === 'remove') {
    const { error } = await service.rpc('remove_rider_payment_method', {
      p_payment_method_id: body.payment_method_id,
    });
    if (error) {
      const code = error.message.includes('NOT_FOUND') ? 'NOT_FOUND' : 'VALIDATION';
      return errorResponse(code, error.message, code === 'NOT_FOUND' ? 404 : 400, { request_id: rid });
    }
  } else {
    const { error } = await service.rpc('set_default_rider_payment_method', {
      p_payment_method_id: body.payment_method_id,
    });
    if (error) {
      const code = error.message.includes('NOT_FOUND') ? 'NOT_FOUND' : 'VALIDATION';
      return errorResponse(code, error.message, code === 'NOT_FOUND' ? 404 : 400, { request_id: rid });
    }
  }

  const { data: methods, error: listError } = await service
    .from('rider_payment_methods_safe')
    .select('id, brand, last4, is_default')
    .eq('rider_id', riderId)
    .order('created_at', { ascending: false });

  if (listError) {
    throw new Error(listError.message);
  }

  return jsonResponse({
    data: { methods: methods ?? [] },
    meta: { request_id: rid },
  });
}

export async function handlePaymentsMethodsDefault(
  body: PaymentsMethodsBody,
  authHeader: string,
): Promise<Response> {
  const userClient = createUserClient(authHeader);
  const { data: userData, error: userError } = await userClient.auth.getUser();
  if (userError || !userData.user?.id) {
    return errorResponse('UNAUTHENTICATED', 'Invalid session', 401, {
      request_id: requestId(),
    });
  }

  return handlePaymentsMethods(body, createServiceClient(), userData.user.id);
}
