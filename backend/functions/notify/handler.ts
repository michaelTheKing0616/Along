import { z } from 'zod';
import { loadDispatchCfg } from '../_shared/cfg.ts';
import { createFcmClient, type FcmClient } from '../_shared/fcm.ts';
import { jsonResponse, requestId } from '../_shared/http.ts';
import {
  createRealtimeBroadcastClient,
  type RealtimeBroadcastClient,
} from '../_shared/realtime.ts';
import { createServiceClient } from '../_shared/supabase.ts';
import type { SupabaseClient } from '@supabase/supabase-js';

export const notifyRequestSchema = z.discriminatedUnion('kind', [
  z.object({
    kind: z.literal('trip_request'),
    trip_id: z.string().uuid(),
  }),
]);

export type NotifyRequest = z.infer<typeof notifyRequestSchema>;

type DeviceTokenRow = {
  token: string;
  platform: string;
};

export type NotifyDeps = {
  service: SupabaseClient;
  realtime: RealtimeBroadcastClient;
  fcm: FcmClient;
};

async function tripDriverId(
  service: SupabaseClient,
  tripId: string,
): Promise<{ driverId: string; cityId: string; expiresAt: string }> {
  const { data, error } = await service
    .from('trips')
    .select('driver_id, expires_at, journeys(city_id)')
    .eq('id', tripId)
    .single();

  if (error || !data) {
    throw new Error('NOT_FOUND');
  }

  const journey = data.journeys as { city_id: string } | { city_id: string }[] | null;
  const cityId = Array.isArray(journey) ? journey[0]?.city_id : journey?.city_id;
  if (!cityId) {
    throw new Error('NOT_FOUND');
  }

  return {
    driverId: data.driver_id as string,
    cityId,
    expiresAt: data.expires_at as string,
  };
}

export async function handleNotify(
  body: NotifyRequest,
  deps: NotifyDeps,
): Promise<Response> {
  const rid = requestId();

  if (body.kind === 'trip_request') {
    const { driverId, cityId, expiresAt } = await tripDriverId(deps.service, body.trip_id);

    const { data: tripView, error: viewError } = await deps.service.rpc('build_trip_view', {
      p_trip_id: body.trip_id,
      p_viewer_id: driverId,
    });
    if (viewError) {
      throw new Error(viewError.message);
    }

    await deps.realtime.send({
      topic: `driver:${driverId}`,
      event: 'trip_request',
      payload: {
        type: 'trip_request',
        trip: tripView,
        expires_at: expiresAt,
      },
      private: true,
    });

    const dispatchCfg = await loadDispatchCfg(deps.service, cityId);

    const { data: tokens, error: tokenError } = await deps.service
      .from('device_tokens')
      .select('token, platform')
      .eq('profile_id', driverId)
      .eq('app', 'driver');

    if (tokenError) {
      throw new Error(tokenError.message);
    }

    let pushes = 0;
    for (const row of (tokens ?? []) as DeviceTokenRow[]) {
      await deps.fcm.sendDataMessage({
        token: row.token,
        data: {
          type: 'trip_request',
          trip_id: body.trip_id,
        },
        ttlSeconds: dispatchCfg.requestTtlS,
        collapseKey: `trip_${body.trip_id}`,
        priority: 'high',
      });
      pushes += 1;
    }

    return jsonResponse({
      data: {
        kind: body.kind,
        trip_id: body.trip_id,
        driver_id: driverId,
        fcm_sent: pushes,
      },
      meta: { request_id: rid },
    });
  }

  return jsonResponse({ data: { kind: body.kind }, meta: { request_id: rid } });
}

export function handleNotifyDefault(body: NotifyRequest): Promise<Response> {
  return handleNotify(body, {
    service: createServiceClient(),
    realtime: createRealtimeBroadcastClient(),
    fcm: createFcmClient(async (url, init) => {
      const res = await fetch(url, init);
      return { ok: res.ok, status: res.status, body: await res.text() };
    }),
  });
}
