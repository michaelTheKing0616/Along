import { z } from 'zod';
import { jsonResponse, requestId } from '../_shared/http.ts';
import { createServiceClient } from '../_shared/supabase.ts';
import type { SupabaseClient } from '@supabase/supabase-js';

export const negotiationClockRequestSchema = z.object({}).passthrough();

export type NegotiationClockRequest = z.infer<typeof negotiationClockRequestSchema>;

export type NegotiationClockDeps = {
  service: SupabaseClient;
};

export async function handleNegotiationClock(
  _req: NegotiationClockRequest,
  deps: NegotiationClockDeps,
): Promise<Response> {
  const rid = requestId();

  const { data, error } = await deps.service.rpc('negotiation_clock_tick');
  if (error) {
    throw new Error(error.message);
  }

  return jsonResponse({
    data: data ?? { lapsed: 0 },
    meta: { request_id: rid },
  });
}

export function handleNegotiationClockDefault(
  req: NegotiationClockRequest,
): Promise<Response> {
  return handleNegotiationClock(req, {
    service: createServiceClient(),
  });
}
