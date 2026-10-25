import { assertEquals } from 'jsr:@std/assert@1';
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

  const res = await handleNegotiationClock({}, {
    service: service as never,
    caller: { serviceRole: true },
  });
  assertEquals(called, true);
  assertEquals(res.status, 200);
  const body = await res.json();
  assertEquals(body.data.lapsed, 2);
});

Deno.test('negotiation-clock: non-service caller is rejected', async () => {
  let called = false;
  const res = await handleNegotiationClock({}, {
    service: {
      rpc() {
        called = true;
        return Promise.resolve({ data: { lapsed: 0 }, error: null });
      },
    } as never,
    caller: { serviceRole: false },
  });
  assertEquals(res.status, 403);
  assertEquals(called, false);
});
