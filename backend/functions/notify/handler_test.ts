import { assertEquals } from 'jsr:@std/assert@1';
import type { SupabaseClient } from '@supabase/supabase-js';
import { handleNotify } from './handler.ts';

const SOS_ID = '0e500000-0000-4000-8000-000000000001';
const ADMIN_ID = '0e900000-0000-4000-8000-000000000001';

function createMockService(): SupabaseClient {
  return {
    from(table: string) {
      const chain = {
        select: () => chain,
        eq: () => chain,
        in: () => chain,
        is: () => chain,
        single: () => {
          if (table === 'sos_alerts') {
            return Promise.resolve({ data: { id: SOS_ID }, error: null });
          }
          return Promise.resolve({ data: null, error: { message: 'NOT_FOUND' } });
        },
        then(onFulfilled: (value: { data: unknown; error: null }) => unknown) {
          if (table === 'admin_users') {
            return Promise.resolve({
              data: [{
                id: ADMIN_ID,
                profiles: { phone_e164: '+2348012345678' },
              }],
              error: null,
            }).then(onFulfilled);
          }
          if (table === 'device_tokens') {
            return Promise.resolve({
              data: [{ token: 'fcm-token-1', platform: 'android' }],
              error: null,
            }).then(onFulfilled);
          }
          return Promise.resolve({ data: [], error: null }).then(onFulfilled);
        },
      };
      return chain;
    },
    rpc: (name: string, args?: Record<string, unknown>) => {
      if (name === 'cfg' && args?.p_key === 'sms.provider') {
        return Promise.resolve({ data: '"log"', error: null });
      }
      return Promise.resolve({ data: null, error: { message: `unexpected rpc: ${name}` } });
    },
  } as unknown as SupabaseClient;
}

Deno.test('notify: kind=sos pushes FCM and logs SMS for safety admins', async () => {
  const logs: Record<string, unknown>[] = [];
  let fcmPayload: Record<string, string> | undefined;

  const res = await handleNotify(
    { kind: 'sos', sos_id: SOS_ID },
    {
      service: createMockService(),
      realtime: { send: () => Promise.resolve() },
      fcm: {
        sendDataMessage: async (message) => {
          fcmPayload = message.data;
          return { messageId: 'stub' };
        },
      },
      log: (entry) => logs.push(entry),
    },
  );

  assertEquals(res.status, 200);
  assertEquals(fcmPayload, { type: 'sos', sos_id: SOS_ID });
  assertEquals(logs.length, 1);
  assertEquals(logs[0]?.event, 'sms_sos_log');
  assertEquals(logs[0]?.sos_id, SOS_ID);
  assertEquals(logs[0]?.phone_suffix, '5678');
  assertEquals(logs[0]?.otp, undefined);
});
