import { assertEquals } from 'jsr:@std/assert@1';
import type { SupabaseClient } from '@supabase/supabase-js';
import { type DispatchCaller, handleDispatch } from './handler.ts';

const TRIP_ID = '0f100000-0000-4000-8000-000000000001';
const RIDER_ID = '0f300000-0000-4000-8000-000000000001';
const DRIVER_ID = '0f200000-0000-4000-8000-000000000001';
const STRANGER_ID = '0f400000-0000-4000-8000-000000000001';

function serviceWithTrip(rpcCalls: string[]): SupabaseClient {
  return {
    from() {
      return {
        select() {
          return {
            eq() {
              return {
                maybeSingle: () =>
                  Promise.resolve({
                    data: { rider_id: RIDER_ID, driver_id: DRIVER_ID },
                    error: null,
                  }),
              };
            },
          };
        },
      };
    },
    rpc(name: string) {
      rpcCalls.push(name);
      return Promise.resolve({
        data: { action: 'retargeted', trip_id: TRIP_ID },
        error: null,
      });
    },
  } as unknown as SupabaseClient;
}

function caller(
  partial: Partial<DispatchCaller> & Pick<DispatchCaller, 'serviceRole'>,
): DispatchCaller {
  return { userId: null, ...partial };
}

Deno.test('dispatch: service role calls dispatch_cascade_step', async () => {
  const rpcCalls: string[] = [];
  const res = await handleDispatch(
    {
      trip_id: TRIP_ID,
      declining_driver_id: DRIVER_ID,
      reason: 'busy',
    },
    {
      service: {
        rpc(name: string) {
          rpcCalls.push(name);
          return Promise.resolve({
            data: { action: 'retargeted', trip_id: TRIP_ID },
            error: null,
          });
        },
      } as unknown as SupabaseClient,
      caller: caller({ serviceRole: true }),
    },
  );

  assertEquals(rpcCalls, ['dispatch_cascade_step']);
  assertEquals(res.status, 200);
});

Deno.test('dispatch: non-owner is rejected and the cascade is not run', async () => {
  const rpcCalls: string[] = [];
  const res = await handleDispatch(
    { trip_id: TRIP_ID, declining_driver_id: DRIVER_ID },
    {
      service: serviceWithTrip(rpcCalls),
      caller: caller({ serviceRole: false, userId: STRANGER_ID }),
    },
  );

  assertEquals(res.status, 403);
  const body = await res.json();
  assertEquals(body.error.code, 'FORBIDDEN');
  assertEquals(rpcCalls, []);
});

Deno.test('dispatch: rider cannot decline on behalf of the driver', async () => {
  const rpcCalls: string[] = [];
  const res = await handleDispatch(
    { trip_id: TRIP_ID, declining_driver_id: DRIVER_ID },
    {
      service: serviceWithTrip(rpcCalls),
      caller: caller({ serviceRole: false, userId: RIDER_ID }),
    },
  );

  assertEquals(res.status, 403);
  assertEquals(rpcCalls, []);
});

Deno.test('dispatch: assigned driver may decline as themselves', async () => {
  const rpcCalls: string[] = [];
  const res = await handleDispatch(
    { trip_id: TRIP_ID, declining_driver_id: DRIVER_ID, reason: 'busy' },
    {
      service: serviceWithTrip(rpcCalls),
      caller: caller({ serviceRole: false, userId: DRIVER_ID }),
    },
  );

  assertEquals(res.status, 200);
  assertEquals(rpcCalls, ['dispatch_cascade_step']);
});

Deno.test('dispatch: trip rider may advance their own cascade', async () => {
  const rpcCalls: string[] = [];
  const res = await handleDispatch(
    { trip_id: TRIP_ID },
    {
      service: serviceWithTrip(rpcCalls),
      caller: caller({ serviceRole: false, userId: RIDER_ID }),
    },
  );

  assertEquals(res.status, 200);
  assertEquals(rpcCalls, ['dispatch_cascade_step']);
});

Deno.test('dispatch: missing user id is unauthenticated', async () => {
  const rpcCalls: string[] = [];
  const res = await handleDispatch(
    { trip_id: TRIP_ID },
    {
      service: serviceWithTrip(rpcCalls),
      caller: caller({ serviceRole: false, userId: null }),
    },
  );

  assertEquals(res.status, 401);
  assertEquals(rpcCalls, []);
});
