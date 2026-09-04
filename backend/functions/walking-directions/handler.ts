import { z } from 'zod';
import { errorResponse, jsonResponse, requestId } from '../_shared/http.ts';
import { createOsrmClient, type OsrmClient } from '../_shared/osrm.ts';
import { createServiceClient, createUserClient } from '../_shared/supabase.ts';
import type { Point } from '../_shared/types.ts';

const pointSchema = z.object({
  lat: z.number().min(-90).max(90),
  lng: z.number().min(-180).max(180),
});

export const walkingDirectionsRequestSchema = z.object({
  from: pointSchema,
  to: pointSchema,
  mode_pref: z.enum(['text', 'map', 'audio']),
});

export type WalkingDirectionsRequest = z.infer<typeof walkingDirectionsRequestSchema>;

export type WalkingDirectionsDeps = {
  service?: ReturnType<typeof createServiceClient>;
  user?: ReturnType<typeof createUserClient>;
  osrm?: OsrmClient;
  cityId?: string;
};

function ttsScript(steps: Array<{ instruction: string; distance_m: number }>): string[] {
  return steps.map((s) => {
    if (s.distance_m > 0) {
      return `${s.instruction} for ${s.distance_m} metres`;
    }
    return s.instruction;
  });
}

export async function handleWalkingDirections(
  req: WalkingDirectionsRequest,
  authHeader: string,
  deps?: WalkingDirectionsDeps,
): Promise<Response> {
  const rid = requestId();

  const userClient = deps?.user ?? createUserClient(authHeader);
  const service = deps?.service ?? createServiceClient();

  const { data: authData, error: authError } = await userClient.auth.getUser();
  if (authError || !authData.user) {
    return errorResponse('UNAUTHENTICATED', 'Authentication required', 401, {
      request_id: rid,
    });
  }

  const { from, to, mode_pref: modePref } = req;

  const cityId = deps?.cityId ?? await (async () => {
    const { data, error } = await service.rpc('city_for_lat_lng', {
      p_lat: from.lat,
      p_lng: from.lng,
    });
    if (error) throw error;
    return data as string | null;
  })();

  const { data: walkSpeedRaw, error: walkSpeedError } = await service.rpc('cfg', {
    p_key: 'planner.walk_speed_mps',
    p_city: cityId,
  });
  if (walkSpeedError) throw walkSpeedError;
  const walkSpeedMps = typeof walkSpeedRaw === 'number'
    ? walkSpeedRaw
    : Number(walkSpeedRaw);

  const osrm = deps?.osrm ?? createOsrmClient({ walkSpeedMps });
  const route = await osrm.footRoute(from as Point, to as Point);

  const data: Record<string, unknown> = {
    distance_m: route.distanceM,
    duration_s: route.durationS,
    steps: route.steps,
    polyline: route.polyline,
  };

  if (modePref === 'audio') {
    data.tts_script = ttsScript(route.steps);
  }

  return jsonResponse(
    {
      data,
      meta: {
        request_id: rid,
        degraded: route.degraded || undefined,
      },
    },
    200,
    { 'Access-Control-Allow-Origin': '*' },
  );
}
