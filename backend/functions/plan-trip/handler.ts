import { z } from 'zod';
import { cityForPoint, loadPlannerCfg } from '../_shared/cfg.ts';
import { errorResponse, jsonResponse, requestId } from '../_shared/http.ts';
import { createOsrmClient, type OsrmClient } from '../_shared/osrm.ts';
import {
  buildDirectCandidates,
  buildMultiLegCandidates,
  directSignature,
  type RawMultiLegItinerary,
} from '../_shared/planner/build.ts';
import { applyRanking } from '../_shared/planner/ranking.ts';
import { createServiceClient, createUserClient } from '../_shared/supabase.ts';
import type {
  PlanCandidate,
  Point,
  RawDirectCandidate,
  StageRow,
} from '../_shared/types.ts';

const pointSchema = z.object({
  lat: z.number().min(-90).max(90),
  lng: z.number().min(-180).max(180),
});

export const planTripRequestSchema = z.object({
  origin: pointSchema,
  destination: pointSchema,
  destination_label: z.string().optional(),
  filters: z.object({
    women_only: z.boolean(),
    load: z.object({
      flagged: z.boolean(),
      size: z.enum(['small', 'medium', 'large']).optional(),
    }),
    modes: z.array(z.string()).nullable().optional(),
  }),
  session_id: z.string().uuid(),
  itinerary_stop_id: z.string().uuid().nullable().optional(),
});

export type PlanTripRequest = z.infer<typeof planTripRequestSchema>;

function stagePoint(stage: StageRow): Point {
  return { lat: stage.lat, lng: stage.lng };
}

async function loadStages(
  service: ReturnType<typeof createServiceClient>,
  stageIds: string[],
): Promise<Map<string, StageRow>> {
  const stageMap = new Map<string, StageRow>();
  if (stageIds.length === 0) return stageMap;

  const { data, error } = await service.rpc('stage_points', {
    p_stage_ids: stageIds,
  });
  if (error) throw error;
  for (const row of (data ?? []) as StageRow[]) {
    stageMap.set(row.id, row);
  }
  return stageMap;
}

export type PlanTripDeps = {
  service?: ReturnType<typeof createServiceClient>;
  user?: ReturnType<typeof createUserClient>;
  osrm?: OsrmClient;
};

export async function handlePlanTrip(
  req: PlanTripRequest,
  authHeader: string,
  deps?: PlanTripDeps,
): Promise<Response> {
  const rid = requestId();
  const started = performance.now();
  let degraded = false;

  const userClient = deps?.user ?? createUserClient(authHeader);
  const service = deps?.service ?? createServiceClient();

  const { data: authData, error: authError } = await userClient.auth.getUser();
  if (authError || !authData.user) {
    return errorResponse('UNAUTHENTICATED', 'Authentication required', 401, {
      request_id: rid,
    });
  }

  const riderId = authData.user.id;
  const { origin, destination, filters } = req;

  const cityId = await cityForPoint(service, origin.lat, origin.lng);
  if (!cityId) {
    return errorResponse('COVERAGE_GAP', 'Origin outside service area', 404, {
      request_id: rid,
    });
  }

  const plannerCfg = await loadPlannerCfg(service, cityId);
  const osrm = deps?.osrm ?? createOsrmClient();

  const [directResult, multiResult] = await Promise.all([
    service.rpc('planner_direct_candidates_latlng', {
      p_origin_lat: origin.lat,
      p_origin_lng: origin.lng,
      p_dest_lat: destination.lat,
      p_dest_lng: destination.lng,
      p_city_id: cityId,
      p_filters: filters,
    }),
    service.rpc('planner_decompose_latlng', {
      p_origin_lat: origin.lat,
      p_origin_lng: origin.lng,
      p_dest_lat: destination.lat,
      p_dest_lng: destination.lng,
      p_city_id: cityId,
      p_filters: filters,
    }),
  ]);

  if (directResult.error) {
    return errorResponse('VALIDATION', directResult.error.message, 400, {
      request_id: rid,
    });
  }
  if (multiResult.error) {
    return errorResponse('VALIDATION', multiResult.error.message, 400, {
      request_id: rid,
    });
  }

  const rawDirect = (directResult.data ?? []) as RawDirectCandidate[];
  const rawMulti = (multiResult.data ?? []) as RawMultiLegItinerary[];

  const stageIds = [...new Set([
    ...rawDirect.flatMap((c) => [c.board_stage_id, c.alight_stage_id]),
    ...rawMulti.flatMap((it) =>
      it.legs.flatMap((l) => [l.from_stage_id, l.to_stage_id])
    ),
  ])];
  const stageMap = await loadStages(service, stageIds);

  const modeCodes = [...new Set([
    ...rawDirect.map((c) => c.mode_code),
    ...rawMulti.flatMap((it) => it.legs.map((l) => l.mode_code)),
  ])];
  const modeMap = new Map<string, import('../_shared/types.ts').ModeRow>();
  if (modeCodes.length > 0) {
    const { data: modes } = await service
      .from('mode_config')
      .select(
        'code, label, icon_key, color_token, comfort_weight, load_capacity, default_dwell_s',
      )
      .in('code', modeCodes);
    for (const m of modes ?? []) {
      modeMap.set(m.code, m as import('../_shared/types.ts').ModeRow);
    }
  }

  const boardStages = [...new Set(rawDirect.map((c) => c.board_stage_id))];
  const alightStages = [...new Set(rawDirect.map((c) => c.alight_stage_id))];

  const boardPoints = boardStages.map((id) => {
    const s = stageMap.get(id);
    return s ? stagePoint(s) : origin;
  });
  const alightPoints = alightStages.map((id) => {
    const s = stageMap.get(id);
    return s ? stagePoint(s) : destination;
  });

  const toBoard = boardPoints.length > 0
    ? await osrm.footTable([origin], boardPoints)
    : { distances: [[]], durations: [[]], degraded: false };
  if (toBoard.degraded) degraded = true;

  const fromAlight = alightPoints.length > 0
    ? await osrm.footTable(alightPoints, [destination])
    : { distances: [], durations: [], degraded: false };
  if (fromAlight.degraded) degraded = true;

  const { candidates: directBuilt, degraded: directDegraded } =
    await buildDirectCandidates({
      service,
      osrm,
      rawCandidates: rawDirect,
      stageMap,
      modeMap,
      origin,
      destination,
      cityId,
      riderId,
      filters,
      plannerCfg,
      toBoard,
      fromAlight,
      boardStages,
      alightStages,
    });
  if (directDegraded) degraded = true;

  const directSignatures = new Set(directBuilt.map(directSignature));

  const { candidates: multiBuilt, degraded: multiDegraded } =
    await buildMultiLegCandidates({
      service,
      osrm,
      itineraries: rawMulti,
      stageMap,
      modeMap,
      origin,
      destination,
      cityId,
      riderId,
      filters,
      plannerCfg,
      directSignatures,
    });
  if (multiDegraded) degraded = true;

  const built: PlanCandidate[] = [...directBuilt, ...multiBuilt];
  const { candidates, sortOrders } = applyRanking(built, plannerCfg);

  let coverageGap: Record<string, unknown> | null = null;
  if (candidates.length === 0) {
    const { data: gap, error: gapError } = await service.rpc(
      'record_coverage_gap_latlng',
      {
        p_rider_id: riderId,
        p_origin_lat: origin.lat,
        p_origin_lng: origin.lng,
        p_dest_lat: destination.lat,
        p_dest_lng: destination.lng,
        p_city_id: cityId,
      },
    );
    if (!gapError && gap) {
      coverageGap = gap as Record<string, unknown>;
    }
  }

  const queryId = crypto.randomUUID();
  const latencyMs = Math.round(performance.now() - started);
  const directCount = candidates.filter((c) => c.kind === 'direct').length;

  const { error: insertError } = await service.rpc('insert_planner_query', {
    p_id: queryId,
    p_rider_id: riderId,
    p_city_id: cityId,
    p_origin_lat: origin.lat,
    p_origin_lng: origin.lng,
    p_dest_lat: destination.lat,
    p_dest_lng: destination.lng,
    p_filters: filters,
    p_candidates: candidates,
    p_candidate_count: candidates.length,
    p_direct_count: directCount,
    p_degraded: degraded,
    p_latency_ms: latencyMs,
  });
  if (insertError) {
    return errorResponse('VALIDATION', insertError.message, 500, { request_id: rid });
  }

  return jsonResponse(
    {
      data: {
        query_id: queryId,
        city_id: cityId,
        degraded,
        candidates,
        sort_orders: sortOrders,
        coverage_gap: coverageGap,
      },
      meta: { request_id: rid, degraded },
    },
    200,
    { 'Access-Control-Allow-Origin': '*' },
  );
}
