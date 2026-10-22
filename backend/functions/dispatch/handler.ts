import { z } from 'zod';
import { errorResponse, jsonResponse, requestId } from '../_shared/http.ts';
import { serviceCallerFromAuthorization } from '../_shared/authz.ts';
import { createServiceClient, createUserClient } from '../_shared/supabase.ts';
import type { SupabaseClient } from '@supabase/supabase-js';

export const dispatchRequestSchema = z.object({
  trip_id: z.string().uuid(),
  declining_driver_id: z.string().uuid().nullable().optional(),
  reason: z.string().nullable().optional(),
});

export type DispatchRequest = z.infer<typeof dispatchRequestSchema>;

export type DispatchCaller = {
  /** Database jobs call dispatch with the service-role key. */
  serviceRole: boolean;
  /** Authenticated user id when the caller is not the service role. */
  userId: string | null;
};

export type DispatchDeps = {
  service: SupabaseClient;
  caller: DispatchCaller;
};

type TripPartyRow = {
  rider_id: string | null;
  driver_id: string | null;
};

export type DispatchDecision = 'allow' | 'unauthenticated' | 'forbidden';

/**
 * Who may advance a dispatch cascade.
 * Service role (internal enqueue) is allowed.
 * A rider may advance their own trip, but may not impersonate a decline.
 * The assigned driver may decline only as themselves.
 * Everyone else is rejected, including when the trip does not exist.
 */
export function decideDispatchCaller(input: {
  caller: DispatchCaller;
  trip: TripPartyRow | null;
  decliningDriverId: string | null;
}): DispatchDecision {
  if (input.caller.serviceRole) return 'allow';
  if (!input.caller.userId) return 'unauthenticated';
  if (!input.trip) return 'forbidden';

  const isRider = input.trip.rider_id === input.caller.userId;
  const isDriver = input.trip.driver_id === input.caller.userId;
  if (!isRider && !isDriver) return 'forbidden';

  if (input.decliningDriverId != null) {
    if (!isDriver || input.decliningDriverId !== input.caller.userId) {
      return 'forbidden';
    }
  }
  return 'allow';
}

async function loadTripParty(
  service: SupabaseClient,
  tripId: string,
): Promise<TripPartyRow | null> {
  const { data, error } = await service
    .from('trips')
    .select('rider_id, driver_id')
    .eq('id', tripId)
    .maybeSingle();

  if (error) {
    throw new Error(error.message);
  }
  return (data as TripPartyRow | null) ?? null;
}

export async function handleDispatch(
  body: DispatchRequest,
  deps: DispatchDeps,
): Promise<Response> {
  const rid = requestId();
  const decliningDriverId = body.declining_driver_id ?? null;

  let trip: TripPartyRow | null = null;
  if (!deps.caller.serviceRole) {
    trip = await loadTripParty(deps.service, body.trip_id);
  }

  const decision = decideDispatchCaller({
    caller: deps.caller,
    trip,
    decliningDriverId,
  });

  if (decision === 'unauthenticated') {
    return errorResponse('UNAUTHENTICATED', 'Authentication required', 401, {
      request_id: rid,
    });
  }
  if (decision === 'forbidden') {
    return errorResponse('FORBIDDEN', 'Not allowed to dispatch this trip', 403, {
      request_id: rid,
    });
  }

  const { data, error } = await deps.service.rpc('dispatch_cascade_step', {
    p_trip_id: body.trip_id,
    p_declining_driver_id: decliningDriverId,
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

export async function handleDispatchDefault(
  body: DispatchRequest,
  authorization: string | null,
): Promise<Response> {
  const caller = serviceCallerFromAuthorization(authorization);
  let userId: string | null = null;
  if (!caller.serviceRole) {
    if (!authorization) {
      return errorResponse('UNAUTHENTICATED', 'Missing authorization header', 401, {
        request_id: requestId(),
      });
    }
    const userClient = createUserClient(authorization);
    const { data, error } = await userClient.auth.getUser();
    if (error || !data.user) {
      return errorResponse('UNAUTHENTICATED', 'Authentication required', 401, {
        request_id: requestId(),
      });
    }
    userId = data.user.id;
  }

  return handleDispatch(body, {
    service: createServiceClient(),
    caller: { serviceRole: caller.serviceRole, userId },
  });
}
