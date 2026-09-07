import { assertEquals } from 'jsr:@std/assert@1';
import { geohashEncode } from './geohash.ts';

Deno.test('geohashEncode matches Abuja point at precision 5 and 7', () => {
  const point = { lat: 9.074, lng: 7.489 };
  assertEquals(geohashEncode(point, 5), 's1t7d');
  assertEquals(geohashEncode(point, 7).length, 7);
});
