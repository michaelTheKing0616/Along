import { assertEquals } from 'jsr:@std/assert@1';
import { handleItineraryPrepare } from './handler.ts';

const TRIP_ID = '0d800000-0000-4000-8000-000000000001';

Deno.test('itinerary-prepare: non-owner service caller is rejected', async () => {
  let rpcCalled = false;
  const res = await handleItineraryPrepare(
    { trip_id: TRIP_ID },
    {
      service: {
        rpc() {
          rpcCalled = true;
          return Promise.resolve({ data: null, error: null });
        },
      } as never,
      caller: { serviceRole: false },
    },
  );

  assertEquals(res.status, 403);
  const body = await res.json();
  assertEquals(body.error.code, 'FORBIDDEN');
  assertEquals(rpcCalled, false);
});
