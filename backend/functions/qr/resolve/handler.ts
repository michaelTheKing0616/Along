import { z } from 'zod';
import { errorResponse, jsonResponse, requestId } from '../../_shared/http.ts';
import { createServiceClient, createUserClient } from '../../_shared/supabase.ts';
import type { SupabaseClient } from '@supabase/supabase-js';

export type QrResolveDeps = {
  service: SupabaseClient;
  riderId?: string;
  clientIp: string;
};

function mapRpcError(message: string, rid: string): Response {
  const upper = message.toUpperCase();
  if (upper.includes('NOT_FOUND')) {
    return errorResponse('NOT_FOUND', 'Driver code not found', 404, { request_id: rid });
  }
  if (upper.includes('FORBIDDEN')) {
    return errorResponse('FORBIDDEN', 'Forbidden', 403, { request_id: rid });
  }
  if (upper.includes('CANDIDATE_EXPIRED')) {
    return errorResponse('CANDIDATE_EXPIRED', 'Token expired or invalid', 410, { request_id: rid });
  }
  return errorResponse('VALIDATION', message, 400, { request_id: rid });
}

export async function handleQrResolve(
  driverCode: string,
  token: string | null,
  deps: QrResolveDeps,
): Promise<Response> {
  const rid = requestId();

  const { data: allowed, error: rateError } = await deps.service.rpc('check_qr_resolve_rate', {
    p_ip: deps.clientIp,
    p_limit: null,
  });

  if (rateError) {
    throw new Error(rateError.message);
  }

  if (allowed === false) {
    return errorResponse('RATE_LIMITED', 'Too many requests', 429, { request_id: rid });
  }

  const { data, error } = await deps.service.rpc('resolve_qr_driver', {
    p_driver_code: driverCode,
    p_rider_id: deps.riderId ?? null,
    p_token: token,
  });

  if (error) {
    return mapRpcError(error.message, rid);
  }

  const payload = data as Record<string, unknown>;
  const response: Record<string, unknown> = { ...payload };
  if (response.warning === null) {
    delete response.warning;
  }

  return jsonResponse({ data: response, meta: { request_id: rid } });
}

export function extractClientIp(req: Request): string {
  return req.headers.get('x-forwarded-for')?.split(',')[0]?.trim()
    ?? req.headers.get('x-real-ip')
    ?? req.headers.get('cf-connecting-ip')
    ?? 'unknown';
}

export async function handleQrResolveRequest(req: Request, driverCode: string): Promise<Response> {
  const url = new URL(req.url);
  const token = url.searchParams.get('t');

  let riderId: string | undefined;
  const authHeader = req.headers.get('Authorization');
  if (authHeader?.startsWith('Bearer ')) {
    const userClient = createUserClient(authHeader);
    const { data: userData } = await userClient.auth.getUser();
    riderId = userData.user?.id;
  }

  return handleQrResolve(driverCode, token, {
    service: createServiceClient(),
    riderId,
    clientIp: extractClientIp(req),
  });
}

export const qrResolveParamsSchema = z.object({
  driver_code: z.string().min(1),
});
