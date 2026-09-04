import { assertEquals, assertExists } from 'jsr:@std/assert@1';
import type { SupabaseClient } from '@supabase/supabase-js';
import type { OsrmClient } from '../_shared/osrm.ts';
import { handlePlanTrip, type PlanTripRequest } from './handler.ts';

const CITY_ID = '0a000000-0000-4000-8000-000000000001';
const RIDER_ID = '0a200000-0000-4000-8000-000000000001';
const BOARD_ID = '0a040000-0000-4000-8000-000000000001';
const ALIGHT_ID = '0a040000-0000-4000-8000-000000000003';
const ROUTE_ID = '0a030000-0000-4000-8000-000000000001';

const baseRequest: PlanTripRequest = {
  origin: { lat: 11.06, lng: 7.7 },
  destination: { lat: 11.065, lng: 7.705 },
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

function createMockServiceClient(candidates: unknown[]): SupabaseClient {
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
          return Promise.resolve({ data: candidates, error: null });
        case 'stage_points':
          return Promise.resolve({
            data: [
              { id: BOARD_ID, name: 'Test Park Alpha', lat: 11.06, lng: 7.7 },
              { id: ALIGHT_ID, name: 'Test Junction Delta', lat: 11.063, lng: 7.703 },
            ],
            error: null,
          });
        case 'resolve_fare':
          return Promise.resolve({
            data: {
              quote_id: '0c100000-0000-4000-8000-000000000001',
              amount: 320,
              currency: 'NGN',
              tier: 1,
              confidence: 0.8,
              components: [{ kind: 'base_fare', amount: 320 }],
              unconfirmed: false,
            },
            error: null,
          });
        case 'record_coverage_gap_latlng':
          return Promise.resolve({
            data: {
              report_id: '0d100000-0000-4000-8000-000000000001',
              nearest_stage: {
                stage_id: BOARD_ID,
                name: 'Test Park Alpha',
                location: { lat: 11.06, lng: 7.7 },
                distance_m: 5000,
              },
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
        in: () =>
          Promise.resolve({
            data: [{
              code: 'car',
              label: 'Car',
              icon_key: 'mode.car',
              color_token: 'mode.car',
              comfort_weight: 4,
              load_capacity: 'medium',
              default_dwell_s: 120,
            }],
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
    footTable: () =>
      Promise.resolve({
        distances: [[100]],
        durations: [[80]],
        degraded: false,
      }),
    carRoute: () =>
      Promise.resolve({ durationS: 500, distanceM: 2000, degraded: false }),
  };
}

function mockDeps(candidates: unknown[]) {
  return {
    service: createMockServiceClient(candidates),
    user: createMockUserClient(),
    osrm: mockOsrmClient(),
  };
}

Deno.test('TS-PLAN-01 handler: happy path with mocked Supabase + OSRM', async () => {
  const res = await handlePlanTrip(
    baseRequest,
    'Bearer test-token',
    mockDeps([parkedCandidate]),
  );
  assertEquals(res.status, 200);

  const body = await res.json();
  assertExists(body.data.query_id);
  assertEquals(body.data.candidates.length, 1);
  assertEquals(body.data.candidates[0].source, 'parked');
  assertEquals(body.data.candidates[0].legs[0].board.stage_id, BOARD_ID);
  assertEquals(body.data.candidates[0].legs[0].alight.stage_id, ALIGHT_ID);
  assertEquals(body.data.coverage_gap, null);
  assertEquals(body.data.degraded, false);
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
  assertEquals(
    body.data.coverage_gap.report_id,
    '0d100000-0000-4000-8000-000000000001',
  );
  assertExists(body.data.coverage_gap.nearest_stage);
});
