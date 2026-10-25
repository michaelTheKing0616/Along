import { assertEquals } from 'jsr:@std/assert@1';
import type { SupabaseClient } from '@supabase/supabase-js';
import type { OsrmClient } from '../_shared/osrm.ts';
import { handleTransferPrefetch } from './handler.ts';

const TRIP_ID = '0d700000-0000-4000-8000-000000000001';

function mockOsrmClient(): OsrmClient {
  const step = {
    instruction: 'Walk to transfer park',
    distance_m: 120,
    bearing: 90,
    maneuver: 'depart',
    geometry: [
      { lat: 11.065, lng: 7.705 },
      { lat: 11.065, lng: 7.706 },
    ],
  };
  return {
    footTable: () => Promise.resolve({ distances: [[100]], durations: [[80]], degraded: false }),
    carRoute: () => Promise.resolve({ durationS: 500, distanceM: 2000, degraded: false }),
    footRoute: () =>
      Promise.resolve({
        distanceM: 120,
        durationS: 96,
        steps: [step],
        polyline: step.geometry,
        degraded: false,
      }),
  };
}

function createMockService(): SupabaseClient {
  return {
    rpc: (name: string, _args?: Record<string, unknown>) => {
      if (name === 'transfer_prefetch_context') {
        return Promise.resolve({
          data: {
            eligible: true,
            journey_id: '0d500000-0000-4000-8000-000000000001',
            after_trip_sequence: 1,
            city_id: '0a000000-0000-4000-8000-000000000001',
            wayfinding_mode: 'text',
            from: { lat: 11.065, lng: 7.705 },
            to: { lat: 11.065, lng: 7.705 },
          },
          error: null,
        });
      }
      if (name === 'cfg') {
        return Promise.resolve({ data: '1.25', error: null });
      }
      if (name === 'store_transfer_walk_prefetch') {
        return Promise.resolve({ data: null, error: null });
      }
      return Promise.resolve({ data: null, error: null });
    },
  } as unknown as SupabaseClient;
}

Deno.test('transfer-prefetch: stores walking directions when eligible', async () => {
  const res = await handleTransferPrefetch(
    { trip_id: TRIP_ID },
    { service: createMockService(), osrm: mockOsrmClient(), caller: { serviceRole: true } },
  );

  assertEquals(res.status, 200);
  const body = await res.json();
  assertEquals(body.data.prefetched, true);
  assertEquals(body.data.trip_id, TRIP_ID);
});

Deno.test('transfer-prefetch: skips when not eligible', async () => {
  const service = {
    rpc: (name: string) => {
      if (name === 'transfer_prefetch_context') {
        return Promise.resolve({ data: { eligible: false }, error: null });
      }
      return Promise.resolve({ data: null, error: null });
    },
  } as unknown as SupabaseClient;

  const res = await handleTransferPrefetch(
    { trip_id: TRIP_ID },
    { service, caller: { serviceRole: true } },
  );
  assertEquals(res.status, 200);
  const body = await res.json();
  assertEquals(body.data.prefetched, false);
});

Deno.test('transfer-prefetch: non-owner caller is rejected', async () => {
  let rpcCalled = false;
  const res = await handleTransferPrefetch(
    { trip_id: TRIP_ID },
    {
      service: {
        rpc() {
          rpcCalled = true;
          return Promise.resolve({ data: { eligible: true }, error: null });
        },
      } as never,
      caller: { serviceRole: false },
    },
  );
  assertEquals(res.status, 403);
  assertEquals(rpcCalled, false);
});
