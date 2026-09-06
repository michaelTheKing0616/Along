import { assertEquals } from 'https://deno.land/std@0.224.0/assert/mod.ts';
import { handleDispatch } from './handler.ts';

Deno.test('dispatch: calls dispatch_cascade_step RPC', async () => {
  let rpcName = '';
  const res = await handleDispatch(
    {
      trip_id: '0f100000-0000-4000-8000-000000000001',
      declining_driver_id: '0f200000-0000-4000-8000-000000000001',
      reason: 'busy',
    },
    {
      service: {
        rpc: (name: string) => {
          rpcName = name;
          return Promise.resolve({
            data: { action: 'retargeted', trip_id: '0f100000-0000-4000-8000-000000000001' },
            error: null,
          });
        },
      } as unknown as import('@supabase/supabase-js').SupabaseClient,
    },
  );

  assertEquals(rpcName, 'dispatch_cascade_step');
  assertEquals(res.status, 200);
});
