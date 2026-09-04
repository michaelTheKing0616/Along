import { z } from 'zod';
import { loadPresenceFanoutCfg } from '../_shared/cfg.ts';
import { jsonResponse, requestId } from '../_shared/http.ts';
import {
  createRealtimeBroadcastClient,
  type RealtimeBroadcastClient,
} from '../_shared/realtime.ts';
import { createServiceClient } from '../_shared/supabase.ts';
import type { SupabaseClient } from '@supabase/supabase-js';

export const presenceFanoutRequestSchema = z.object({
  city_id: z.string().uuid().optional(),
});

export type PresenceFanoutRequest = z.infer<typeof presenceFanoutRequestSchema>;

type FanoutTarget = {
  city_id: string;
  city_slug: string;
  geohash5: string;
  centroid_lat: number;
  centroid_lng: number;
  radius_m: number;
};

type AmbientCellsPayload = {
  type: 'cells';
  cells: unknown[];
  as_of: string;
};

export type PresenceFanoutDeps = {
  service: SupabaseClient;
  realtime: RealtimeBroadcastClient;
};

export async function handlePresenceFanout(
  req: PresenceFanoutRequest,
  deps: PresenceFanoutDeps,
): Promise<Response> {
  const rid = requestId();
  const cfg = await loadPresenceFanoutCfg(deps.service, req.city_id ?? null);

  const { data: targets, error: targetsError } = await deps.service.rpc(
    'presence_fanout_targets',
  );
  if (targetsError) {
    throw new Error(targetsError.message);
  }

  const rows = (targets ?? []) as FanoutTarget[];
  const filtered = req.city_id
    ? rows.filter((r) => r.city_id === req.city_id)
    : rows;

  let published = 0;

  for (const target of filtered) {
    const { data: ambient, error: ambientError } = await deps.service.rpc(
      'ambient_vehicles',
      {
        p_lat: target.centroid_lat,
        p_lng: target.centroid_lng,
        p_radius_m: target.radius_m,
      },
    );
    if (ambientError) {
      throw new Error(ambientError.message);
    }

    const body = ambient as { as_of?: string; cells?: unknown[] };
    const payload: AmbientCellsPayload = {
      type: 'cells',
      cells: body.cells ?? [],
      as_of: body.as_of ?? new Date().toISOString(),
    };

    const topic = `ambient:${target.city_slug}:${target.geohash5}`;
    await deps.realtime.send({
      topic,
      event: 'cells',
      payload,
      private: true,
    });
    published += 1;
  }

  return jsonResponse({
    data: {
      published,
      fanout_interval_s: cfg.fanoutIntervalS,
      targets: filtered.length,
    },
    meta: { request_id: rid },
  });
}

export function handlePresenceFanoutDefault(
  req: PresenceFanoutRequest,
): Promise<Response> {
  return handlePresenceFanout(req, {
    service: createServiceClient(),
    realtime: createRealtimeBroadcastClient(),
  });
}
