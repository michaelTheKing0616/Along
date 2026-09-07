import { assertEquals } from 'jsr:@std/assert@1';
import {
  getPlanTripCache,
  resetEdgeCachesForTests,
} from '../_shared/edge_cache.ts';
import { handleCacheMetrics } from './handler.ts';

Deno.test('cache-metrics: reports hit ratio after cache activity', async () => {
  resetEdgeCachesForTests();
  const cache = getPlanTripCache();
  cache.set('k', { query_id: 'x' }, 60_000);
  cache.get('k');
  cache.get('missing');

  const res = handleCacheMetrics();
  assertEquals(res.status, 200);
  const body = await res.json();
  assertEquals(body.data.plan_trip.hits, 1);
  assertEquals(body.data.plan_trip.misses, 1);
  assertEquals(body.data.plan_trip.hit_ratio, 0.5);
  assertEquals(typeof body.data.places_search.hits, 'number');
  assertEquals(typeof body.data.graph_bundle.misses, 'number');
});
