import { assertEquals, assertExists } from 'jsr:@std/assert@1';
import type { SupabaseClient } from '@supabase/supabase-js';
import type { PhotonClient } from '../_shared/photon.ts';
import { handlePlacesSearch, type PlacesSearchRequest } from './handler.ts';

const CITY_ID = 'b1000000-0000-4000-8000-000000000001';
const PARK_ID = 'b1100000-0000-4000-8000-00000000000b';
const STAGE_ID = 'b1200000-0000-4000-8000-000000000001';

const baseRequest: PlacesSearchRequest = {
  q: 'wuse',
  near: { lat: 9.074, lng: 7.489 },
  city_id: CITY_ID,
  limit: 8,
};

function placesCfgValue(key: string): unknown {
  const values: Record<string, unknown> = {
    'places.search_radius_m': '5000',
    'places.trigram_min_similarity': '0.2',
    'places.photon_timeout_ms': '800',
  };
  return values[key] ?? null;
}

function createMockServiceClient(graphRows: unknown[]): SupabaseClient {
  return {
    rpc: (name: string, args?: Record<string, unknown>) => {
      if (name === 'cfg') {
        return Promise.resolve({
          data: placesCfgValue(String(args?.p_key)),
          error: null,
        });
      }
      if (name === 'places_search_graph') {
        return Promise.resolve({ data: graphRows, error: null });
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

function mockPhotonClient(places: Array<{ name: string; area: string; lat: number; lng: number }>): PhotonClient {
  return {
    search: (_q, _near, limit) =>
      Promise.resolve({
        degraded: false,
        results: places.slice(0, limit).map((p) => ({
          kind: 'place' as const,
          name: p.name,
          area: p.area,
          location: { lat: p.lat, lng: p.lng },
          distance_m: 1200,
        })),
      }),
  };
}

const graphRows = [
  {
    kind: 'park',
    id: PARK_ID,
    name: 'Wuse Market',
    area: 'Abuja',
    lat: 9.074,
    lng: 7.489,
    distance_m: 50,
  },
  {
    kind: 'stage',
    id: STAGE_ID,
    name: 'Wuse Stage',
    area: 'Abuja',
    lat: 9.075,
    lng: 7.490,
    distance_m: 120,
  },
];

Deno.test('places-search: parks and stages rank before Photon places', async () => {
  const res = await handlePlacesSearch(
    baseRequest,
    'Bearer test-token',
    {
      service: createMockServiceClient(graphRows),
      user: createMockUserClient(),
      photon: mockPhotonClient([
        { name: 'Wuse General Hospital', area: 'Abuja', lat: 9.076, lng: 7.491 },
        { name: 'Wuse Zone 5', area: 'Abuja', lat: 9.077, lng: 7.492 },
      ]),
    },
  );

  assertEquals(res.status, 200);
  const body = await res.json();
  const results = body.data.results;
  assertEquals(results.length, 4);
  assertEquals(results[0].kind, 'park');
  assertEquals(results[0].name, 'Wuse Market');
  assertEquals(results[1].kind, 'stage');
  assertEquals(results[2].kind, 'place');
  assertEquals(results[3].kind, 'place');
  assertExists(body.meta.request_id);
});

Deno.test('places-search: graph-only results when limit filled by parks/stages', async () => {
  const res = await handlePlacesSearch(
    { ...baseRequest, limit: 2 },
    'Bearer test-token',
    {
      service: createMockServiceClient(graphRows),
      user: createMockUserClient(),
      photon: mockPhotonClient([
        { name: 'Should Not Appear', area: 'Abuja', lat: 9.08, lng: 7.5 },
      ]),
    },
  );

  assertEquals(res.status, 200);
  const body = await res.json();
  assertEquals(body.data.results.length, 2);
  assertEquals(body.data.results.every((r: { kind: string }) => r.kind !== 'place'), true);
});
