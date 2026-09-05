import { assertEquals, assertExists } from 'jsr:@std/assert@1';
import type { SupabaseClient } from '@supabase/supabase-js';
import { loadPresenceFanoutCfg } from '../_shared/cfg.ts';
import type { RealtimeBroadcastClient } from '../_shared/realtime.ts';
import { handleNotify, type NotifyRequest } from '../notify/handler.ts';
import { handlePresenceFanout } from '../presence-fanout/handler.ts';

const CITY_ID = '0a000000-0000-4000-8000-000000000001';
const TRIP_ID = '0f100000-0000-4000-8000-000000000001';
const DRIVER_ID = '0f200000-0000-4000-8000-000000000001';

function createMockFanoutService(): SupabaseClient {
  return {
    rpc: (name: string, args?: Record<string, unknown>) => {
      if (name === 'cfg') {
        const key = String(args?.p_key);
        const values: Record<string, unknown> = {
          'presence.fanout_interval_s': '10',
          'presence.fanout_radius_m': '3000',
        };
        return Promise.resolve({ data: values[key] ?? null, error: null });
      }
      if (name === 'presence_fanout_targets') {
        return Promise.resolve({
          data: [{
            city_id: CITY_ID,
            city_slug: 'zaria-test',
            geohash5: 's0k8t',
            centroid_lat: 11.06,
            centroid_lng: 7.7,
            radius_m: 3000,
          }],
          error: null,
        });
      }
      if (name === 'ambient_vehicles') {
        return Promise.resolve({
          data: {
            as_of: '2026-09-04T12:00:00.000Z',
            cells: [{
              cell: 's0k8tz',
              count_bucket: '1-2',
              heading_sectors: [0, 1, 0, 0, 0, 0, 0, 0],
            }],
          },
          error: null,
        });
      }
      return Promise.resolve({ data: null, error: { message: `unexpected rpc: ${name}` } });
    },
  } as unknown as SupabaseClient;
}

Deno.test('presence-fanout: publishes ambient cells and reports cfg interval ≤ 10 s', async () => {
  const broadcasts: Array<{ topic: string; payload: unknown }> = [];
  const realtime: RealtimeBroadcastClient = {
    send: ({ topic, payload }) => {
      broadcasts.push({ topic, payload });
      return Promise.resolve();
    },
  };

  const res = await handlePresenceFanout({}, {
    service: createMockFanoutService(),
    realtime,
  });

  assertEquals(res.status, 200);
  const body = await res.json();
  assertEquals(body.data.published, 1);
  assertEquals(body.data.fanout_interval_s, 10);
  assertEquals(body.data.fanout_interval_s <= 10, true);
  assertEquals(broadcasts.length, 1);
  assertEquals(broadcasts[0].topic, 'ambient:zaria-test:s0k8t');
  assertEquals((broadcasts[0].payload as { type: string }).type, 'cells');
  assertExists(body.meta.request_id);
});

Deno.test('loadPresenceFanoutCfg: fanout interval comes from app_config', async () => {
  const cfg = await loadPresenceFanoutCfg(createMockFanoutService(), null);
  assertEquals(cfg.fanoutIntervalS, 10);
  assertEquals(cfg.fanoutIntervalS <= 10, true);
  assertEquals(cfg.fanoutRadiusM, 3000);
});


function createMockNotifyService(): SupabaseClient {
  return {
    rpc: (name: string, args?: Record<string, unknown>) => {
      if (name === 'cfg') {
        const key = String(args?.p_key);
        if (key === 'dispatch.request_ttl_s') {
          return Promise.resolve({ data: '25', error: null });
        }
        return Promise.resolve({ data: null, error: null });
      }
      if (name === 'build_trip_view') {
        return Promise.resolve({
          data: {
            trip_id: TRIP_ID,
            status: 'requested',
            live_channel: `trip:${TRIP_ID}`,
          },
          error: null,
        });
      }
      return Promise.resolve({ data: null, error: { message: `unexpected rpc: ${name}` } });
    },
    from: (table: string) => {
      if (table === 'trips') {
        return {
          select: () => ({
            eq: () => ({
              single: () => Promise.resolve({
                data: {
                  driver_id: DRIVER_ID,
                  expires_at: '2026-09-04T12:00:25.000Z',
                  journeys: { city_id: CITY_ID },
                },
                error: null,
              }),
            }),
          }),
        };
      }
      if (table === 'device_tokens') {
        return {
          select: () => ({
            eq: (_col: string, val: unknown) => ({
              eq: () => Promise.resolve({
                data: val === DRIVER_ID
                  ? [{ token: 'fcm-token-1', platform: 'android' }]
                  : [],
                error: null,
              }),
            }),
          }),
        };
      }
      return {
        select: () => ({
          eq: () => ({
            eq: () => Promise.resolve({ data: [], error: null }),
          }),
        }),
      };
    },
  } as unknown as SupabaseClient;
}

Deno.test('notify: trip_request broadcasts to driver channel and sends FCM data push', async () => {
  const broadcasts: Array<{ topic: string; event: string }> = [];
  const fcmTokens: string[] = [];

  const body: NotifyRequest = { kind: 'trip_request', trip_id: TRIP_ID };

  const res = await handleNotify(body, {
    service: createMockNotifyService(),
    realtime: {
      send: ({ topic, event }) => {
        broadcasts.push({ topic, event });
        return Promise.resolve();
      },
    },
    fcm: {
      sendDataMessage: (msg) => {
        fcmTokens.push(msg.token);
        assertEquals(msg.ttlSeconds, 25);
        assertEquals(msg.collapseKey, `trip_${TRIP_ID}`);
        return Promise.resolve({ messageId: 'fcm-1' });
      },
    },
  });

  assertEquals(res.status, 200);
  const json = await res.json();
  assertEquals(json.data.driver_id, DRIVER_ID);
  assertEquals(json.data.fcm_sent, 1);
  assertEquals(broadcasts.length, 1);
  assertEquals(broadcasts[0].topic, `driver:${DRIVER_ID}`);
  assertEquals(broadcasts[0].event, 'trip_request');
  assertEquals(fcmTokens, ['fcm-token-1']);
});
