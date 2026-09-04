import { assertEquals, assertExists } from 'jsr:@std/assert@1';
import { createOsrmClient } from './osrm.ts';
import type { Point } from './types.ts';

Deno.test('TS-PLAN-05: OSRM down uses fallback and marks degraded', async () => {
  const client = createOsrmClient({
    baseUrl: '',
    fetchFn: () => {
      throw new Error('connection refused');
    },
  });

  const origin: Point = { lat: 11.06, lng: 7.7 };
  const dest: Point = { lat: 11.065, lng: 7.705 };

  const table = await client.footTable([origin], [dest]);
  assertEquals(table.degraded, true);
  assertExists(table.distances[0]?.[0]);
  assertExists(table.durations[0]?.[0]);
  assertEquals(table.distances[0]![0]! > 0, true);

  const route = await client.carRoute(origin, dest);
  assertEquals(route.degraded, true);
  assertEquals(route.durationS > 0, true);

  const foot = await client.footRoute(origin, dest);
  assertEquals(foot.degraded, true);
  assertEquals(foot.distanceM > 0, true);
  assertEquals(foot.steps.length >= 1, true);
});
