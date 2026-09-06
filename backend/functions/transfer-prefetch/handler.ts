import { z } from 'zod';
import { jsonResponse, requestId } from '../_shared/http.ts';
import { handleWalkingDirections } from '../walking-directions/handler.ts';
import { createOsrmClient, type OsrmClient } from '../_shared/osrm.ts';
import { createServiceClient } from '../_shared/supabase.ts';
import type { SupabaseClient } from '@supabase/supabase-js';

export const transferPrefetchRequestSchema = z.object({
  trip_id: z.string().uuid(),
});

export type TransferPrefetchRequest = z.infer<typeof transferPrefetchRequestSchema>;

type PrefetchContext = {
  eligible: boolean;
  journey_id?: string;
  after_trip_sequence?: number;
  city_id?: string;
  wayfinding_mode?: 'text' | 'map' | 'audio';
  from?: { lat: number; lng: number };
  to?: { lat: number; lng: number };
};

export type TransferPrefetchDeps = {
  service: SupabaseClient;
  osrm?: OsrmClient;
};

export async function handleTransferPrefetch(
  body: TransferPrefetchRequest,
  deps: TransferPrefetchDeps,
): Promise<Response> {
  const rid = requestId();

  const { data: ctxRaw, error: ctxError } = await deps.service.rpc('transfer_prefetch_context', {
    p_trip_id: body.trip_id,
  });
  if (ctxError) {
    throw new Error(ctxError.message);
  }

  const ctx = ctxRaw as PrefetchContext;
  if (!ctx?.eligible || !ctx.from || !ctx.to) {
    return jsonResponse({
      data: { trip_id: body.trip_id, prefetched: false, reason: 'not_eligible' },
      meta: { request_id: rid },
    });
  }

  const { data: walkSpeedRaw, error: walkSpeedError } = await deps.service.rpc('cfg', {
    p_key: 'planner.walk_speed_mps',
    p_city: ctx.city_id ?? null,
  });
  if (walkSpeedError) throw walkSpeedError;
  const walkSpeedMps = typeof walkSpeedRaw === 'number'
    ? walkSpeedRaw
    : Number(walkSpeedRaw);

  const modePref = ctx.wayfinding_mode ?? 'text';
  const mockUser = {
    auth: {
      getUser: () => Promise.resolve({ data: { user: { id: 'service-role' } }, error: null }),
    },
  } as unknown as ReturnType<typeof import('../_shared/supabase.ts').createUserClient>;

  const walkRes = await handleWalkingDirections(
    { from: ctx.from, to: ctx.to, mode_pref: modePref },
    'Bearer service',
    {
      service: deps.service,
      user: mockUser,
      osrm: deps.osrm ?? createOsrmClient({ walkSpeedMps }),
      cityId: ctx.city_id,
    },
  );

  if (walkRes.status !== 200) {
    const errBody = await walkRes.json().catch(() => ({}));
    throw new Error(
      typeof errBody === 'object' && errBody && 'error' in errBody
        ? String((errBody as { error?: { message?: string } }).error?.message ?? 'walking-directions failed')
        : 'walking-directions failed',
    );
  }

  const walkBody = await walkRes.json();
  const directions = walkBody.data as Record<string, unknown>;

  const { error: storeError } = await deps.service.rpc('store_transfer_walk_prefetch', {
    p_trip_id: body.trip_id,
    p_directions: directions,
  });
  if (storeError) {
    throw new Error(storeError.message);
  }

  return jsonResponse({
    data: {
      trip_id: body.trip_id,
      journey_id: ctx.journey_id,
      after_trip_sequence: ctx.after_trip_sequence,
      prefetched: true,
    },
    meta: { request_id: rid },
  });
}

export function handleTransferPrefetchDefault(body: TransferPrefetchRequest): Promise<Response> {
  return handleTransferPrefetch(body, {
    service: createServiceClient(),
  });
}
