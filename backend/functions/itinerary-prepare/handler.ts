import { z } from 'zod';
import {
  forbiddenUnlessServiceRole,
  type ServiceCaller,
  serviceCallerFromAuthorization,
} from '../_shared/authz.ts';
import { jsonResponse, requestId } from '../_shared/http.ts';
import { handlePlanTrip } from '../plan-trip/handler.ts';
import { createServiceClient } from '../_shared/supabase.ts';
import type { SupabaseClient } from '@supabase/supabase-js';

export const itineraryPrepareRequestSchema = z.object({
  trip_id: z.string().uuid(),
});

export type ItineraryPrepareRequest = z.infer<typeof itineraryPrepareRequestSchema>;

function planLoadSize(raw: string | undefined): 'small' | 'medium' | 'large' | undefined {
  if (raw === 'small' || raw === 'medium' || raw === 'large') return raw;
  return undefined;
}

type PrepareContext = {
  eligible: boolean;
  stop_id?: string;
  rider_id?: string;
  city_id?: string;
  filters?: {
    women_only?: boolean;
    load?: { flagged: boolean; size?: string };
  };
  from?: { lat: number; lng: number };
  to?: { lat: number; lng: number };
  destination_label?: string;
  reason?: string;
  remaining_s?: number;
};

export type ItineraryPrepareDeps = {
  service: SupabaseClient;
  planTrip?: typeof handlePlanTrip;
  caller: ServiceCaller;
};

export async function handleItineraryPrepare(
  body: ItineraryPrepareRequest,
  deps: ItineraryPrepareDeps,
): Promise<Response> {
  const rid = requestId();
  const denied = forbiddenUnlessServiceRole(deps.caller, rid);
  if (denied) return denied;

  const { data: ctxRaw, error: ctxError } = await deps.service.rpc('itinerary_prepare_context', {
    p_trip_id: body.trip_id,
  });
  if (ctxError) {
    throw new Error(ctxError.message);
  }

  const ctx = ctxRaw as PrepareContext;
  if (!ctx?.eligible || !ctx.from || !ctx.to || !ctx.stop_id) {
    return jsonResponse({
      data: {
        trip_id: body.trip_id,
        prepared: false,
        reason: ctx?.reason ?? 'not_eligible',
        remaining_s: ctx?.remaining_s,
      },
      meta: { request_id: rid },
    });
  }

  const planTrip = deps.planTrip ?? handlePlanTrip;
  const mockUser = {
    auth: {
      getUser: () => Promise.resolve({ data: { user: { id: ctx.rider_id } }, error: null }),
    },
  } as unknown as ReturnType<typeof import('../_shared/supabase.ts').createUserClient>;

  const filters = {
    women_only: ctx.filters?.women_only ?? false,
    load: {
      flagged: ctx.filters?.load?.flagged ?? false,
      size: planLoadSize(ctx.filters?.load?.size),
    },
    modes: null,
  };

  const planRes = await planTrip(
    {
      origin: ctx.from,
      destination: ctx.to,
      destination_label: ctx.destination_label,
      filters,
      session_id: crypto.randomUUID(),
      itinerary_stop_id: ctx.stop_id,
    },
    'Bearer service',
    {
      service: deps.service,
      user: mockUser,
    },
  );

  if (planRes.status !== 200) {
    const errBody = await planRes.json().catch(() => ({}));
    throw new Error(
      typeof errBody === 'object' && errBody && 'error' in errBody
        ? String((errBody as { error?: { message?: string } }).error?.message ?? 'plan-trip failed')
        : 'plan-trip failed',
    );
  }

  const planBody = await planRes.json();
  const planData = planBody.data as Record<string, unknown>;
  const preparedPlan = {
    ...planData,
    candidate_set_only: true,
    match_requires_request_trip: true,
    not_booked: true,
  };

  const { error: storeError } = await deps.service.rpc('store_itinerary_prepared_plan', {
    p_stop_id: ctx.stop_id,
    p_prepared_plan: preparedPlan,
  });
  if (storeError) {
    throw new Error(storeError.message);
  }

  return jsonResponse({
    data: {
      trip_id: body.trip_id,
      stop_id: ctx.stop_id,
      prepared: true,
    },
    meta: { request_id: rid },
  });
}

export function handleItineraryPrepareDefault(
  body: ItineraryPrepareRequest,
  authorization: string | null,
): Promise<Response> {
  return handleItineraryPrepare(body, {
    service: createServiceClient(),
    caller: serviceCallerFromAuthorization(authorization),
  });
}
