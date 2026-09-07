import { assertEquals } from 'jsr:@std/assert@1';
import { filtersHash, TtlCache } from './edge_cache.ts';

Deno.test('TtlCache returns value before TTL and misses after expiry', () => {
  const cache = new TtlCache<string>(4);
  cache.set('k', 'v', 1000, 1000);
  assertEquals(cache.get('k', 1500), 'v');
  assertEquals(cache.get('k', 2100), undefined);
  const stats = cache.stats();
  assertEquals(stats.hits, 1);
  assertEquals(stats.misses, 1);
  assertEquals(Math.round(stats.hit_ratio * 100), 50);
});

Deno.test('filtersHash is stable regardless of key order', () => {
  const a = filtersHash({ women_only: false, load: { flagged: true, size: 'medium' } });
  const b = filtersHash({ load: { size: 'medium', flagged: true }, women_only: false });
  assertEquals(a, b);
});
