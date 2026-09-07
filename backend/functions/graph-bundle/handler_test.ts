import { assertEquals, assertExists } from 'jsr:@std/assert@1';
import type { SupabaseClient } from '@supabase/supabase-js';
import { TtlCache } from '../_shared/edge_cache.ts';
import { handleGraphBundle, type GraphBundlePayload, type GraphBundleRequest } from './handler.ts';

const CITY_ID = '0a000000-0000-4000-8000-000000000001';
const GRAPH_VERSION = 'abc123version';

const baseRequest: GraphBundleRequest = {
  city_id: CITY_ID,
};

function cacheCfgValue(key: string): unknown {
  const values: Record<string, unknown> = {
    'cache.plan_trip_ttl_s': '60',
    'cache.places_ttl_s': '86400',
    'cache.graph_bundle_ttl_s': '3600',
    'cache.graph_bundle_max_parks': '500',
    'cache.graph_bundle_max_stages': '2000',
    'cache.graph_bundle_max_legs': '5000',
  };
  return values[key] ?? null;
}

const compactBundle = {
  parks: [{ id: 'p1', name: 'Alpha', lat: 11.06, lng: 7.7 }],
  stages: [{ id: 's1', route_id: 'r1', sequence: 0, name: 'Stage', lat: 11.061, lng: 7.701, is_official_park: true }],
  legs: [{
    id: 'l1',
    route_id: 'r1',
    from_stage_id: 's1',
    to_stage_id: 's2',
    mode_code: 'car',
    fare_amount: 200,
    fare_currency: 'NGN',
    in_vehicle_time_estimate_s: 600,
    avg_wait_time_estimate_s: 120,
  }],
  truncated: false,
};

function createMockServiceClient(): SupabaseClient {
  return {
    rpc: (name: string, args?: Record<string, unknown>) => {
      if (name === 'cfg') {
        return Promise.resolve({
          data: cacheCfgValue(String(args?.p_key)),
          error: null,
        });
      }
      if (name === 'city_graph_version') {
        return Promise.resolve({ data: GRAPH_VERSION, error: null });
      }
      if (name === 'graph_bundle_compact') {
        return Promise.resolve({ data: compactBundle, error: null });
      }
      return Promise.resolve({
        data: null,
        error: { message: `unexpected rpc: ${name}` },
      });
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

Deno.test('graph-bundle: returns compact parks/stages/legs with graph_version', async () => {
  const cache = new TtlCache<GraphBundlePayload>(4);
  const res = await handleGraphBundle(baseRequest, 'Bearer test-token', {
    service: createMockServiceClient(),
    user: createMockUserClient(),
    cache,
  });

  assertEquals(res.status, 200);
  assertEquals(res.headers.get('X-Cache'), 'MISS');
  const body = await res.json();
  assertEquals(body.data.city_id, CITY_ID);
  assertEquals(body.data.graph_version, GRAPH_VERSION);
  assertEquals(body.data.parks.length, 1);
  assertEquals(body.data.stages.length, 1);
  assertEquals(body.data.legs.length, 1);
  assertEquals(body.data.truncated, false);
  assertExists(body.meta.request_id);
});

Deno.test('graph-bundle cache: second request is X-Cache HIT', async () => {
  const cache = new TtlCache<GraphBundlePayload>(4);
  const deps = {
    service: createMockServiceClient(),
    user: createMockUserClient(),
    cache,
  };

  await handleGraphBundle(baseRequest, 'Bearer test-token', deps);
  const second = await handleGraphBundle(baseRequest, 'Bearer test-token', deps);
  assertEquals(second.headers.get('X-Cache'), 'HIT');
});
