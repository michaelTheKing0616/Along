import { z } from 'zod';
import { cityForPoint, loadCacheCfg, loadPlannerCfg } from '../_shared/cfg.ts';
import {
  filtersHash,
  getPlanTripCache,
  type TtlCache,
} from '../_shared/edge_cache.ts';
import { geohashEncode } from '../_shared/geohash.ts';
import { errorResponse, jsonResponse, requestId } from '../_shared/http.ts';
import { createOsrmClient, type OsrmClient } from '../_shared/osrm.ts';
import {
  buildDirectCandidates,
  buildMultiLegCandidates,
  directSignature,
  type RawMultiLegItinerary,
} from '../_shared/planner/build.ts';
import {
  rehydratePlanTripCandidates,
  toShareablePlanTripCache,
  type ShareablePlanTripCache,
} from '../_shared/planner/rehydrate.ts';
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
  cache?: TtlCache<Record<string, unknown>> | false;
};

function planTripCacheKey(
  cityId: string,
  origin: Point,
  destination: Point,
  filters: PlanTripRequest['filters'],
): string {
  const originGh = geohashEncode(origin, 7);
  const destGh = geohashEncode(destination, 7);
  return `${cityId}:${originGh}:${destGh}:${filtersHash(filters)}`;
}

export async function handlePlanTrip(
  req: PlanTripRequest,
  authHeader: string,
  deps?: PlanTripDeps,
): Promise<Response> {
  const rid = requestId();
  const cache = deps?.cache === false ? null : (deps?.cache ?? getPlanTripCache());

  const userClient = deps?.user ?? createUserClient(authHeader);
  const service = deps?.service ?? createServiceClient();

  const { data: authData, error: authError } = await userClient.auth.getUser();
  if (authError || !authData.user) {
    return errorResponse('UNAUTHENTICATED', 'Authentication required', 401, {
      request_id: rid,
    });
  }

  const { origin, destination, filters } = req;
  const cityId = await cityForPoint(service, origin.lat, origin.lng);
  if (!cityId) {
    return errorResponse('COVERAGE_GAP', 'Origin outside service area', 404, {
      request_id: rid,
    });
  }

  const cacheCfg = await loadCacheCfg(service, cityId);
  const cacheKey = planTripCacheKey(cityId, origin, destination, filters);

  if (cache) {
    const hit = cache.get(cacheKey) as ShareablePlanTripCache | undefined;
    if (hit) {
      console.log(JSON.stringify({ event: 'cache_hit', cache: 'plan_trip', key: cacheKey }));
      const rehydrated = await rehydratePlanTripFromCache(
        hit,
        {
          riderId: authData.user.id,
          cityId,
          filters: req.filters,
          origin: req.origin,
          destination: req.destination,
          service,
          rid,
        },
      );
      if (rehydrated) {
        const headers = new Headers(rehydrated.headers);
        headers.set('X-Cache', 'HIT');
        return new Response(rehydrated.body, { status: rehydrated.status, headers });
      }
    }
  }

  const response = await executePlanTrip(req, deps, {
    rid,
    riderId: authData.user.id,
    cityId,
  });
  if (response.status !== 200 || !cache) {
    return response;
  }

  const body = await response.clone().json();
  if (body?.data) {
    cache.set(
      cacheKey,
      toShareablePlanTripCache(body.data as Record<string, unknown>),
      cacheCfg.planTripTtlS * 1000,
    );
    console.log(JSON.stringify({ event: 'cache_miss', cache: 'plan_trip', key: cacheKey }));
  }

  const headers = new Headers(response.headers);
  headers.set('X-Cache', 'MISS');
  return new Response(response.body, { status: response.status, headers });
}

async function rehydratePlanTripFromCache(
  cached: ShareablePlanTripCache,
  ctx: {
    riderId: string;
    cityId: string;
    filters: PlanTripRequest['filters'];
    origin: Point;
    destination: Point;
    service: ReturnType<typeof createServiceClient>;
    rid: string;
  },
): Promise<Response | null> {
  const candidates = await rehydratePlanTripCandidates(
    ctx.service,
    cached,
    ctx.riderId,
    ctx.filters,
  );
  if (!candidates) return null;

  const queryId = crypto.randomUUID();
  const directCount = candidates.filter((c) => c.kind === 'direct').length;

  const { error: insertError } = await ctx.service.rpc('insert_planner_query', {
    p_id: queryId,
    p_rider_id: ctx.riderId,
    p_city_id: ctx.cityId,
    p_origin_lat: ctx.origin.lat,
    p_origin_lng: ctx.origin.lng,
    p_dest_lat: ctx.destination.lat,
    p_dest_lng: ctx.destination.lng,
    p_filters: ctx.filters,
    p_candidates: candidates,
    p_candidate_count: candidates.length,
    p_direct_count: directCount,
    p_degraded: cached.degraded,
    p_latency_ms: 0,
  });
  if (insertError) {
    return errorResponse('VALIDATION', insertError.message, 500, {
      request_id: ctx.rid,
    });
  }

  return jsonResponse(
    {
      data: {
        query_id: queryId,
        city_id: cached.city_id,
        degraded: cached.degraded,
        candidates,
        sort_orders: cached.sort_orders,
        coverage_gap: cached.coverage_gap,
      },
      meta: { request_id: ctx.rid, degraded: cached.degraded },
    },
    200,
    { 'Access-Control-Allow-Origin': '*' },
  );
}

async function executePlanTrip(
  req: PlanTripRequest,
  deps: PlanTripDeps | undefined,
  ctx: { rid: string; riderId: string; cityId: string },
): Promise<Response> {
  const { rid, riderId, cityId } = ctx;
  const started = performance.now();
  let degraded = false;

  const service = deps?.service ?? createServiceClient();
  const { origin, destination, filters } = req;

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
