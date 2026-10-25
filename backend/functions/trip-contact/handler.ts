import { z } from 'zod';
import type { SupabaseClient } from '@supabase/supabase-js';
import { errorResponse, jsonResponse, requestId } from '../_shared/http.ts';
import { createServiceClient, createUserClient } from '../_shared/supabase.ts';
import {
  type ContactProvider,
  contactProviderFromEnv,
  ContactProviderNotConfigured,
} from '../_shared/contact/mod.ts';

export const tripContactSchema = z.object({
  trip_id: z.string().uuid(),
  channel: z.enum(['call', 'sms']),
});

export type TripContactRequest = z.infer<typeof tripContactSchema>;

export type TripContactDeps = {
  callerId: string;
  service: SupabaseClient;
  provider: ContactProvider;
  log: (entry: Record<string, unknown>) => void;
};

/** Contact actions live for 2 minutes; the app asks again on the next tap. */
export const CONTACT_TTL_SECONDS = 120;

type Target = {
  trip_id: string;
  caller_role: 'rider' | 'driver';
  caller_phone: string | null;
  target_phone: string | null;
};

function suffix(phone: string): string {
  return phone.replace(/\D/g, '').slice(-4);
}

export async function handleTripContact(
  body: TripContactRequest,
  deps: TripContactDeps,
): Promise<Response> {
  const rid = requestId();
  const { data, error } = await deps.service.rpc('trip_contact_target', {
    p_trip_id: body.trip_id,
    p_caller: deps.callerId,
  });

  if (error) {
    const msg = error.message ?? '';
    if (msg.includes('FORBIDDEN')) {
      return errorResponse('FORBIDDEN', 'Not on this trip', 403, { request_id: rid });
    }
    if (msg.includes('NOT_FOUND')) {
      return errorResponse('NOT_FOUND', 'Trip not found', 404, { request_id: rid });
    }
    if (msg.includes('STATE_INVALID')) {
      return errorResponse('STATE_INVALID', 'Trip is not live', 409, { request_id: rid });
    }
    return errorResponse('INTERNAL', 'Could not resolve contact', 500, { request_id: rid });
  }

  const target = data as Target;
  if (!target?.target_phone || !target.caller_phone) {
    return errorResponse('CONTACT_UNAVAILABLE', 'No phone on file', 409, { request_id: rid });
  }

  try {
    const action = await deps.provider.createSession({
      tripId: body.trip_id,
      channel: body.channel,
      callerPhone: target.caller_phone,
      targetPhone: target.target_phone,
      ttlSeconds: CONTACT_TTL_SECONDS,
    });
    deps.log({
      event: 'trip_contact',
      provider: deps.provider.name,
      trip_id: body.trip_id,
      caller_role: target.caller_role,
      channel: body.channel,
      masked: action.masked,
      target_suffix: suffix(target.target_phone),
    });
    return jsonResponse({ data: action, meta: { request_id: rid } });
  } catch (err) {
    if (err instanceof ContactProviderNotConfigured) {
      deps.log({ event: 'trip_contact_unavailable', provider: deps.provider.name });
      return errorResponse('CONTACT_UNAVAILABLE', 'Contact relay is not configured', 503, {
        request_id: rid,
      });
    }
    throw err;
  }
}

export async function handleTripContactDefault(
  body: TripContactRequest,
  authHeader: string,
): Promise<Response> {
  const userClient = createUserClient(authHeader);
  const { data: userData, error } = await userClient.auth.getUser();
  if (error || !userData.user?.id) {
    return errorResponse('UNAUTHENTICATED', 'Invalid session', 401, { request_id: requestId() });
  }
  let provider: ContactProvider;
  try {
    provider = contactProviderFromEnv((k) => Deno.env.get(k));
  } catch {
    return errorResponse('CONTACT_UNAVAILABLE', 'Contact relay is not configured', 503, {
      request_id: requestId(),
    });
  }
  return handleTripContact(body, {
    callerId: userData.user.id,
    service: createServiceClient(),
    provider,
    log: (entry) => console.log(JSON.stringify(entry)),
  });
}
