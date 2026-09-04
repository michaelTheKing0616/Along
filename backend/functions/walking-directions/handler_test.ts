import { assertEquals, assertExists } from 'jsr:@std/assert@1';
import type { SupabaseClient } from '@supabase/supabase-js';
import type { OsrmClient } from '../_shared/osrm.ts';
import { handleWalkingDirections, type WalkingDirectionsRequest } from './handler.ts';

const CITY_ID = 'b1000000-0000-4000-8000-000000000001';

const baseRequest: WalkingDirectionsRequest = {
  from: { lat: 9.074, lng: 7.489 },
  to: { lat: 9.076, lng: 7.491 },
  mode_pref: 'text',
};

function plannerCfgValue(key: string): unknown {
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

function createMockServiceClient(): SupabaseClient {
  return {
    rpc: (name: string, args?: Record<string, unknown>) => {
      if (name === 'cfg') {
        return Promise.resolve({
          data: plannerCfgValue(String(args?.p_key)),
          error: null,
        });
      }
      return Promise.resolve({ data: null, error: null });
    },
  } as unknown as SupabaseClient;
}

function createMockUserClient(): SupabaseClient {
  return {
    auth: {
      getUser: () =>
        Promise.resolve({ data: { user: { id: '0a200000-0000-4000-8000-000000000001' } }, error: null }),
    },
  } as unknown as SupabaseClient;
}

function mockOsrmClient(degraded: boolean): OsrmClient {
  const step = {
    instruction: 'Walk north on Wuse Road',
    distance_m: 180,
    bearing: 10,
    maneuver: 'depart',
    geometry: [
      { lat: 9.074, lng: 7.489 },
      { lat: 9.076, lng: 7.491 },
    ],
  };
  return {
    footTable: () =>
      Promise.resolve({ distances: [[100]], durations: [[80]], degraded: false }),
    carRoute: () =>
      Promise.resolve({ durationS: 500, distanceM: 2000, degraded: false }),
    footRoute: () =>
      Promise.resolve({
        distanceM: 180,
        durationS: 144,
        steps: [step],
        polyline: step.geometry,
        degraded,
      }),
  };
}

Deno.test('walking-directions: OSRM foot route with mocked client', async () => {
  const res = await handleWalkingDirections(
    baseRequest,
    'Bearer test-token',
    {
      service: createMockServiceClient(),
      user: createMockUserClient(),
      osrm: mockOsrmClient(false),
      cityId: CITY_ID,
    },
  );

  assertEquals(res.status, 200);
  const body = await res.json();
  assertEquals(body.data.distance_m, 180);
  assertEquals(body.data.duration_s, 144);
  assertEquals(body.data.steps.length, 1);
  assertEquals(body.data.polyline.length, 2);
  assertEquals(body.meta.degraded, undefined);
  assertExists(body.meta.request_id);
});

Deno.test('walking-directions: OSRM down degrades with fallback route', async () => {
  const res = await handleWalkingDirections(
    baseRequest,
    'Bearer test-token',
    {
      service: createMockServiceClient(),
      user: createMockUserClient(),
      osrm: mockOsrmClient(true),
      cityId: CITY_ID,
    },
  );

  assertEquals(res.status, 200);
  const body = await res.json();
  assertEquals(body.meta.degraded, true);
  assertEquals(body.data.steps.length >= 1, true);
  assertEquals(body.data.polyline.length >= 2, true);
});

Deno.test('walking-directions: audio mode includes tts_script', async () => {
  const res = await handleWalkingDirections(
    { ...baseRequest, mode_pref: 'audio' },
    'Bearer test-token',
    {
      service: createMockServiceClient(),
      user: createMockUserClient(),
      osrm: mockOsrmClient(false),
      cityId: CITY_ID,
    },
  );

  assertEquals(res.status, 200);
  const body = await res.json();
  assertExists(body.data.tts_script);
  assertEquals(Array.isArray(body.data.tts_script), true);
  assertEquals(body.data.tts_script.length, 1);
});
