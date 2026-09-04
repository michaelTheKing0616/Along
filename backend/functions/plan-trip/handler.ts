import { z } from 'zod';
import { cityForPoint, loadPlannerCfg } from '../_shared/cfg.ts';
import { fallbackWalkDistanceM, walkSeconds } from '../_shared/geo.ts';
import { errorResponse, jsonResponse, requestId } from '../_shared/http.ts';
import { createOsrmClient } from '../_shared/osrm.ts';
import {
  applyRanking,
  computeMetrics,
  loadWarning,
  parkedWaitS,
} from '../_shared/planner/ranking.ts';
import { createServiceClient, createUserClient } from '../_shared/supabase.ts';
import type {
  Fare,
  FareComponent,
  ModeRow,
  PlanCandidate,
  PlanCandidateLeg,
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

type FareResolution = {
  quote_id: string;
  amount: number;
  currency: string;
  tier: number;
  confidence: number;
  components: Array<{ kind: string; amount: number; ref_id?: string }>;
  unconfirmed: boolean;
};

function money(amount: number, currency: string) {
  return { amount: amount.toFixed(2), currency };
}

function mapFare(res: FareResolution, expiresAt: string): Fare {
  const components: FareComponent[] = (res.components ?? []).map((c) => ({
    kind: c.kind,
    ref_id: c.ref_id,
    label: c.kind.replace(/_/g, ' '),
    amount: money(Number(c.amount), res.currency),
  }));
  return {
    total: money(res.amount, res.currency),
    tier: res.tier,
    confidence: res.confidence,
    unconfirmed: res.unconfirmed,
    components,
    quote_id: res.quote_id,
    expires_at: expiresAt,
  };
}

function stagePoint(stage: StageRow): Point {
  return { lat: stage.lat, lng: stage.lng };
}

function boardStop(
  stage: StageRow,
  walkM: number,
  walkS: number,
) {
  return {
    stage_id: stage.id,
    name: stage.name,
    location: { lat: stage.lat, lng: stage.lng },
    walk_m: Math.round(walkM),
    walk_s: walkS,
    wayfinding_available: true,
  };
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

export async function handlePlanTrip(
  req: PlanTripRequest,
  authHeader: string,
): Promise<Response> {
  const rid = requestId();
  const started = performance.now();
  let degraded = false;

  const userClient = createUserClient(authHeader);
  const service = createServiceClient();

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
  const osrm = createOsrmClient();

  const { data: rawRows, error: candError } = await service.rpc(
    'planner_direct_candidates_latlng',
    {
      p_origin_lat: origin.lat,
      p_origin_lng: origin.lng,
      p_dest_lat: destination.lat,
      p_dest_lng: destination.lng,
      p_city_id: cityId,
      p_filters: filters,
    },
  );
  if (candError) {
    return errorResponse('VALIDATION', candError.message, 400, { request_id: rid });
  }

  const rawCandidates = (rawRows ?? []) as RawDirectCandidate[];
  const stageIds = [...new Set(
    rawCandidates.flatMap((c) => [c.board_stage_id, c.alight_stage_id]),
  )];
  const stageMap = await loadStages(service, stageIds);

  const modeCodes = [...new Set(rawCandidates.map((c) => c.mode_code))];
  const modeMap = new Map<string, ModeRow>();
  if (modeCodes.length > 0) {
    const { data: modes } = await service
      .from('mode_config')
      .select(
        'code, label, icon_key, color_token, comfort_weight, load_capacity, default_dwell_s',
      )
      .in('code', modeCodes);
    for (const m of modes ?? []) {
      modeMap.set(m.code, m as ModeRow);
    }
  }

  const boardStages = [...new Set(rawCandidates.map((c) => c.board_stage_id))];
  const alightStages = [...new Set(rawCandidates.map((c) => c.alight_stage_id))];

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

  const boardIndex = new Map<string, number>();
  boardStages.forEach((id, i) => boardIndex.set(id, i));
  const alightIndex = new Map<string, number>();
  alightStages.forEach((id, i) => alightIndex.set(id, i));

  const built: PlanCandidate[] = [];

  for (const raw of rawCandidates) {
    const board = stageMap.get(raw.board_stage_id);
    const alight = stageMap.get(raw.alight_stage_id);
    const mode = modeMap.get(raw.mode_code);
    if (!board || !alight || !mode) continue;

    const bi = boardIndex.get(raw.board_stage_id) ?? 0;
    const ai = alightIndex.get(raw.alight_stage_id) ?? 0;

    const originWalkM = toBoard.distances[0]?.[bi] ??
      Math.round(fallbackWalkDistanceM(origin, stagePoint(board)));
    const originWalkS = toBoard.durations[0]?.[bi] ??
      walkSeconds(originWalkM, plannerCfg.walkSpeedMps);

    const destWalkM = fromAlight.distances[ai]?.[0] ??
      Math.round(fallbackWalkDistanceM(stagePoint(alight), destination));
    const destWalkS = fromAlight.durations[ai]?.[0] ??
      walkSeconds(destWalkM, plannerCfg.walkSpeedMps);

    const walkTotalM = originWalkM + destWalkM;

    let inVehicleS = raw.in_vehicle_time_estimate_s ?? 0;
    if (inVehicleS <= 0 && raw.route_id) {
      const route = await osrm.carRoute(stagePoint(board), stagePoint(alight));
      if (route.degraded) degraded = true;
      inVehicleS = Math.round(route.durationS * plannerCfg.sharedVehicleFactor);
    }

    let waitS = raw.avg_wait_time_estimate_s ?? plannerCfg.defaultWaitS;
    if (raw.source === 'parked') {
      waitS = parkedWaitS(mode);
    }

    const loadJson = filters.load.flagged
      ? { flagged: true, size: filters.load.size ?? null }
      : null;

    const fareArgs: Record<string, unknown> = {
      p_mode_code: raw.mode_code,
      p_city_id: cityId,
      p_load: loadJson,
      p_rider_id: riderId,
    };
    if (raw.profile_id) {
      fareArgs.p_profile_id = raw.profile_id;
      fareArgs.p_from_stage_id = raw.board_stage_id;
      fareArgs.p_to_stage_id = raw.alight_stage_id;
    } else if (raw.route_id) {
      fareArgs.p_route_id = raw.route_id;
      fareArgs.p_from_stage_id = raw.board_stage_id;
      fareArgs.p_to_stage_id = raw.alight_stage_id;
    }

    const { data: fareData, error: fareError } = await service.rpc(
      'resolve_fare',
      fareArgs,
    );
    if (fareError || !fareData) continue;

    const fareRes = fareData as FareResolution;
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString();
    const fare = mapFare(fareRes, expiresAt);

    const warning = filters.load.flagged
      ? loadWarning(mode.load_capacity, filters.load.size, plannerCfg.warnCapacities)
      : null;

    const leg: PlanCandidateLeg = {
      leg_index: 0,
      mode: {
        code: mode.code,
        label: mode.label,
        icon_key: mode.icon_key,
        color_token: mode.color_token,
      },
      board: boardStop(board, originWalkM, originWalkS),
      alight: {
        stage_id: alight.id,
        name: alight.name,
        location: { lat: alight.lat, lng: alight.lng },
      },
      route_id: raw.route_id,
      route_leg_ids: raw.route_leg_ids ?? [],
      in_vehicle_s: inVehicleS,
      wait_s: waitS,
      fare,
      supply: raw.supply,
      load_warning: warning,
    };

    const walkS = originWalkS + destWalkS;
    const metrics = computeMetrics({
      walkTotalM,
      walkS,
      waitS,
      inVehicleS,
      transferCount: 0,
      totalFare: fare.total,
      mode,
      cfg: plannerCfg,
    });

    built.push({
      candidate_id: crypto.randomUUID(),
      kind: 'direct',
      source: raw.source as PlanCandidate['source'],
      viable_direct: true,
      legs: [leg],
      transfers: [],
      metrics,
    });
  }

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
