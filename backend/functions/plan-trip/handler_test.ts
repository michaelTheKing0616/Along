import { assertEquals, assertExists, assertNotEquals } from 'jsr:@std/assert@1';
import type { SupabaseClient } from '@supabase/supabase-js';
import type { OsrmClient } from '../_shared/osrm.ts';
import { applyRanking, computeMetrics } from '../_shared/planner/ranking.ts';
import type { Metrics, ModeRow, PlanCandidate } from '../_shared/types.ts';
import { handlePlanTrip, type PlanTripRequest } from './handler.ts';

const CITY_ID = '0a000000-0000-4000-8000-000000000001';
const RIDER_ID = '0a200000-0000-4000-8000-000000000001';
const BOARD_ID = '0a040000-0000-4000-8000-000000000001';
const ALIGHT_ID = '0a040000-0000-4000-8000-000000000003';
const ROUTE_ID = '0a030000-0000-4000-8000-000000000001';
const MULTI_BOARD = '0a040000-0000-4000-8000-000000000005';
const MULTI_ALIGHT = '0a043000-0000-4000-8000-000000000002';

const baseRequest: PlanTripRequest = {
  origin: { lat: 11.06, lng: 7.7 },
  destination: { lat: 11.068, lng: 7.708 },
  filters: { women_only: false, load: { flagged: false } },
  session_id: '0b100000-0000-4000-8000-000000000001',
};

const parkedCandidate = {
  source: 'parked',
  route_id: ROUTE_ID,
  profile_id: null,
  board_stage_id: BOARD_ID,
  alight_stage_id: ALIGHT_ID,
  mode_code: 'car',
  route_leg_ids: [],
  in_vehicle_time_estimate_s: 600,
  avg_wait_time_estimate_s: 120,
  supply: { kind: 'parked', vehicles_bucket: 'few' },
};

const slowDirectCandidate = {
  ...parkedCandidate,
  route_id: '0a030000-0000-4000-8000-000000000003',
  alight_stage_id: '0a042000-0000-4000-8000-000000000003',
  in_vehicle_time_estimate_s: 5400,
};

const multiLegItinerary = {
  kind: 'multi_leg',
  origin_park_id: '0a020000-0000-4000-8000-000000000001',
  destination_park_id: '0a020000-0000-4000-8000-000000000003',
  legs: [
    {
      route_id: ROUTE_ID,
      mode_code: 'car',
      from_stage_id: BOARD_ID,
      to_stage_id: MULTI_BOARD,
      route_leg_ids: [],
      in_vehicle_time_estimate_s: 600,
      avg_wait_time_estimate_s: 60,
    },
    {
      route_id: '0a030000-0000-4000-8000-000000000004',
      mode_code: 'keke',
      from_stage_id: MULTI_BOARD,
      to_stage_id: MULTI_ALIGHT,
      route_leg_ids: [],
      in_vehicle_time_estimate_s: 600,
      avg_wait_time_estimate_s: 60,
    },
  ],
  transfers: [{ park_id: '0a020000-0000-4000-8000-000000000002', walk_distance_m: 0, transfer_time_s: 120 }],
};

function cfgValue(key: string): unknown {
  const values: Record<string, unknown> = {
    'planner.max_candidates': '12',
    'planner.walk_speed_mps': '1.25',
    'planner.shared_vehicle_factor': '1.25',
    'planner.default_wait_s': '300',
    'planner.direct_viability_factor': '1.5',
    'planner.direct_viability_slack_s': '300',
    'planner.recommended_weights': '{"fare":0.4,"time":0.4,"strenuous":0.2}',
    'planner.strenuous_weights': '{"transfer":1,"walk_per_100m":0.25,"mode":0.5}',
    'load.warn_capacities':
      '{"small":["none"],"medium":["none","small"],"large":["none","small","medium"]}',
  };
  return values[key] ?? null;
}

const stageRows = [
  { id: BOARD_ID, name: 'Test Park Alpha', lat: 11.06, lng: 7.7 },
  { id: ALIGHT_ID, name: 'Test Junction Delta', lat: 11.063, lng: 7.703 },
  { id: MULTI_BOARD, name: 'Test Park Beta', lat: 11.065, lng: 7.705 },
  { id: MULTI_ALIGHT, name: 'Test Park Gamma', lat: 11.068, lng: 7.708 },
  { id: '0a042000-0000-4000-8000-000000000003', name: 'Gamma Stage', lat: 11.068, lng: 7.708 },
];

function createMockServiceClient(
  directCandidates: unknown[],
  multiItineraries: unknown[] = [],
): SupabaseClient {
  return {
    rpc: (name: string, args?: Record<string, unknown>) => {
      switch (name) {
        case 'city_for_lat_lng':
          return Promise.resolve({ data: CITY_ID, error: null });
        case 'cfg':
          return Promise.resolve({
            data: cfgValue(String(args?.p_key)),
            error: null,
          });
        case 'planner_direct_candidates_latlng':
          return Promise.resolve({ data: directCandidates, error: null });
        case 'planner_decompose_latlng':
          return Promise.resolve({ data: multiItineraries, error: null });
        case 'stage_points': {
          const ids = (args?.p_stage_ids ?? []) as string[];
          return Promise.resolve({
            data: stageRows.filter((s) => ids.includes(s.id)),
            error: null,
          });
        }
        case 'resolve_fare': {
          const routeId = args?.p_route_id as string | undefined;
          const amount = routeId === '0a030000-0000-4000-8000-000000000003' ? 1000
            : routeId === '0a030000-0000-4000-8000-000000000004' ? 80
            : routeId === ROUTE_ID ? 320
            : 200;
          return Promise.resolve({
            data: {
              quote_id: '0c100000-0000-4000-8000-000000000001',
              amount,
              currency: 'NGN',
              tier: 1,
              confidence: 0.8,
              components: [{ kind: 'base_fare', amount }],
              unconfirmed: false,
            },
            error: null,
          });
        }
        case 'record_coverage_gap_latlng':
          return Promise.resolve({
            data: {
              report_id: '0d100000-0000-4000-8000-000000000001',
              nearest_stage: { stage_id: BOARD_ID, name: 'Test Park Alpha', distance_m: 5000 },
              ambient_vehicle_count: 0,
            },
            error: null,
          });
        case 'insert_planner_query':
          return Promise.resolve({ data: null, error: null });
        default:
          return Promise.resolve({
            data: null,
            error: { message: `unexpected rpc: ${name}` },
          });
      }
    },
    from: () => ({
      select: () => ({
        in: (_col: string, codes: string[]) =>
          Promise.resolve({
            data: codes.map((code) => ({
              code,
              label: code,
              icon_key: `mode.${code}`,
              color_token: `mode.${code}`,
              comfort_weight: code === 'keke' ? 6 : 4,
              load_capacity: 'medium',
              default_dwell_s: 120,
            })),
            error: null,
          }),
      }),
    }),
  } as unknown as SupabaseClient;
}

function createMockUserClient(): SupabaseClient {
  return {
    auth: {
      getUser: () =>
        Promise.resolve({ data: { user: { id: RIDER_ID } }, error: null }),
    },
  } as unknown as SupabaseClient;
}

function mockOsrmClient(): OsrmClient {
  return {
    footTable: (_from: Point[], _to: Point[]) =>
      Promise.resolve({
        distances: [[100]],
        durations: [[80]],
        degraded: false,
      }),
    carRoute: () =>
      Promise.resolve({ durationS: 500, distanceM: 2000, degraded: false }),
    footRoute: () =>
      Promise.resolve({
        distanceM: 100,
        durationS: 80,
        steps: [],
        polyline: [],
        degraded: false,
      }),
  };
}

type Point = { lat: number; lng: number };

function mockDeps(direct: unknown[], multi: unknown[] = []) {
  return {
    service: createMockServiceClient(direct, multi),
    user: createMockUserClient(),
    osrm: mockOsrmClient(),
  };
}

Deno.test('TS-PLAN-01: direct and multi-leg both returned; viable direct; recommended[0] direct', async () => {
  const res = await handlePlanTrip(
    baseRequest,
    'Bearer test-token',
    mockDeps([parkedCandidate], [multiLegItinerary]),
  );
  assertEquals(res.status, 200);

  const body = await res.json();
  const kinds = body.data.candidates.map((c: { kind: string }) => c.kind);
  assertEquals(kinds.includes('direct'), true);
  assertEquals(kinds.includes('multi_leg'), true);

  const recommendedId = body.data.sort_orders.recommended[0];
  const recommended = body.data.candidates.find(
    (c: { candidate_id: string }) => c.candidate_id === recommendedId,
  );
  assertEquals(recommended.kind, 'direct');
  assertEquals(recommended.viable_direct, true);
});

Deno.test('TS-PLAN-02: slow direct unviable; multi-leg recommended first; direct still present', async () => {
  const res = await handlePlanTrip(
    baseRequest,
    'Bearer test-token',
    mockDeps([slowDirectCandidate], [multiLegItinerary]),
  );
  assertEquals(res.status, 200);

  const body = await res.json();
  const direct = body.data.candidates.find((c: { kind: string }) => c.kind === 'direct');
  const multi = body.data.candidates.find((c: { kind: string }) => c.kind === 'multi_leg');
  assertExists(direct);
  assertExists(multi);
  assertEquals(direct.viable_direct, false);
  assertEquals(body.data.sort_orders.recommended[0], multi.candidate_id);
});

Deno.test('TS-PLAN-04: metrics on every candidate; explain sums to recommended_score', async () => {
  const res = await handlePlanTrip(
    baseRequest,
    'Bearer test-token',
    mockDeps([parkedCandidate], [multiLegItinerary]),
  );
  const body = await res.json();
  for (const c of body.data.candidates) {
    assertExists(c.metrics.total_fare);
    assertExists(c.metrics.total_time_s);
    const sum = Object.values(c.metrics.explain as Record<string, number>)
      .reduce((a, b) => a + b, 0);
    assertEquals(Math.abs(sum - c.metrics.recommended_score) < 1e-6, true);
  }
});

Deno.test('TS-PLAN-06 handler: coverage gap branch with mocked Supabase + OSRM', async () => {
  const res = await handlePlanTrip(
    baseRequest,
    'Bearer test-token',
    mockDeps([]),
  );
  assertEquals(res.status, 200);

  const body = await res.json();
  assertEquals(body.data.candidates.length, 0);
  assertExists(body.data.coverage_gap);
});

const mode: ModeRow = {
  code: 'car',
  label: 'Car',
  icon_key: 'mode.car',
  color_token: 'mode.car',
  comfort_weight: 4,
  load_capacity: 'medium',
  default_dwell_s: 120,
};

const cfg = {
  maxCandidates: 12,
  walkSpeedMps: 1.25,
  sharedVehicleFactor: 1.25,
  defaultWaitS: 300,
  directViabilityFactor: 1.5,
  directViabilitySlackS: 300,
  recommendedWeights: { fare: 0.4, time: 0.4, strenuous: 0.2 },
  strenuousWeights: { transfer: 1, walk_per_100m: 0.25, mode: 0.5 },
  warnCapacities: {
    small: ['none'],
    medium: ['none', 'small'],
    large: ['none', 'small', 'medium'],
  },
};

function makeCandidate(
  id: string,
  kind: 'direct' | 'multi_leg',
  fare: number,
  time: number,
  transfers: number,
  walkM: number,
): PlanCandidate {
  const partial = computeMetrics({
    walkTotalM: walkM,
    walkS: Math.round(walkM / 1.25),
    waitS: 60,
    inVehicleS: time,
    transferCount: transfers,
    totalFare: { amount: fare.toFixed(2), currency: 'NGN' },
    mode,
    cfg,
  });
  const metrics: Metrics = {
    ...partial,
    recommended_score: 0,
    explain: { fare: 0, time: 0, strenuous: 0 },
  };
  return {
    candidate_id: id,
    kind,
    source: kind === 'direct' ? 'graph' : 'graph',
    viable_direct: kind === 'direct',
    legs: [],
    transfers: [],
    metrics,
  };
}

Deno.test('TS-PLAN-03: four sort orders differ on engineered dataset', () => {
  const candidates = [
    makeCandidate('cheap', 'multi_leg', 100, 5000, 2, 800),
    makeCandidate('fast', 'direct', 900, 800, 0, 100),
    makeCandidate('easy', 'direct', 600, 3000, 0, 50),
    makeCandidate('balanced', 'multi_leg', 400, 2000, 1, 200),
  ];

  const { sortOrders } = applyRanking(candidates, cfg);
  const all = [
    sortOrders.cheapest.join(','),
    sortOrders.fastest.join(','),
    sortOrders.least_strenuous.join(','),
    sortOrders.recommended.join(','),
  ];
  const unique = new Set(all);
  assertEquals(unique.size >= 3, true);
  assertNotEquals(sortOrders.cheapest[0], sortOrders.fastest[0]);
});

Deno.test('TS-PLAN-09 handler: candidate count respects max_candidates', async () => {
  const manyDirect = Array.from({ length: 15 }, (_, i) => ({
    ...parkedCandidate,
    board_stage_id: BOARD_ID,
    alight_stage_id: ALIGHT_ID,
    route_id: ROUTE_ID,
    in_vehicle_time_estimate_s: 600 + i * 10,
  }));

  const res = await handlePlanTrip(
    baseRequest,
    'Bearer test-token',
    mockDeps(manyDirect, []),
  );
  const body = await res.json();
  assertEquals(body.data.candidates.length <= 12, true);
});
