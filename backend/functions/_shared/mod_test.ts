import { assertEquals } from 'jsr:@std/assert@1';

Deno.test('_shared bootstrap', () => {
  assertEquals(1 + 1, 2);
});
