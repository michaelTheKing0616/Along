import { assertEquals } from 'jsr:@std/assert';
import { handleNegotiationClock } from './handler.ts';

Deno.test('negotiation-clock invokes negotiation_clock_tick RPC', async () => {
  let called = false;
  const service = {
    rpc(name: string) {
      assertEquals(name, 'negotiation_clock_tick');
      called = true;
      return Promise.resolve({ data: { lapsed: 2 }, error: null });
    },
  };

  const res = await handleNegotiationClock({}, { service: service as never });
  assertEquals(called, true);
  assertEquals(res.status, 200);
  const body = await res.json();
  assertEquals(body.data.lapsed, 2);
});
