import { z } from 'zod';
import { jsonResponse, requestId } from '../_shared/http.ts';
import { createServiceClient } from '../_shared/supabase.ts';
import type { SupabaseClient } from '@supabase/supabase-js';

export const dispatchRequestSchema = z.object({
  trip_id: z.string().uuid(),
  declining_driver_id: z.string().uuid().nullable().optional(),
  reason: z.string().nullable().optional(),
});

export type DispatchRequest = z.infer<typeof dispatchRequestSchema>;

export type DispatchDeps = {
  service: SupabaseClient;
};

export async function handleDispatch(
  body: DispatchRequest,
  deps: DispatchDeps,
): Promise<Response> {
  const rid = requestId();

  const { data, error } = await deps.service.rpc('dispatch_cascade_step', {
    p_trip_id: body.trip_id,
    p_declining_driver_id: body.declining_driver_id ?? null,
    p_reason: body.reason ?? null,
  });

  if (error) {
    throw new Error(error.message);
  }

  return jsonResponse({
    data: data ?? { action: 'unknown' },
    meta: { request_id: rid },
  });
}

export function handleDispatchDefault(body: DispatchRequest): Promise<Response> {
  return handleDispatch(body, {
    service: createServiceClient(),
  });
}
