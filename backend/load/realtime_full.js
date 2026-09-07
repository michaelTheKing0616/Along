import ws from 'k6/ws';
import { check, sleep } from 'k6';
import { Counter, Trend } from 'k6/metrics';
import { FULL_CITY, THRESHOLDS } from './thresholds.js';
import {
  broadcastTripLocTest,
  phxJoin,
  realtimeWsUrl,
  triggerPresenceFanout,
  triggerPresenceFanoutDirect,
} from './lib/supabase.js';

const fanoutLatency = new Trend('ambient_fanout_latency_ms', true);
const realtimeMsgLatency = new Trend('realtime_message_latency_ms', true);
const tripEvents = new Counter('trip_broadcast_events');

const fixture = JSON.parse(open(__ENV.LOAD_TOKENS_FILE || `${__ENV.PWD}/.tokens.json`));

const baseUrl = __ENV.SUPABASE_URL || 'http://127.0.0.1:54321';
const anonKey = __ENV.SUPABASE_ANON_KEY;
const serviceKey = __ENV.SUPABASE_SERVICE_ROLE_KEY;
const functionsUrl = __ENV.SUPABASE_FUNCTIONS_URL || `${baseUrl}/functions/v1`;
const fanoutMode = __ENV.FANOUT_MODE || 'direct';
const duration = __ENV.DURATION || FULL_CITY.duration;
const tripSubscriberVus = Number(__ENV.TRIP_SUBSCRIBER_VUS) || FULL_CITY.tripSubscriberVus;
const tripBroadcastRate = Number(__ENV.TRIP_BROADCAST_RATE) || 10;

export const options = {
  scenarios: {
    trip_subscribers: {
      executor: 'constant-vus',
      vus: tripSubscriberVus,
      duration,
      exec: 'tripSubscribe',
      startTime: '5s',
    },
    trip_broadcast_pump: {
      executor: 'constant-arrival-rate',
      rate: tripBroadcastRate,
      timeUnit: '1s',
      duration,
      preAllocatedVUs: 5,
      maxVUs: 20,
      exec: 'pumpTripBroadcast',
      startTime: '15s',
    },
    fanout_pump: {
      executor: 'constant-arrival-rate',
      rate: 1,
      timeUnit: `${THRESHOLDS.presenceFanoutIntervalS}s`,
      duration,
      preAllocatedVUs: 1,
      maxVUs: 1,
      exec: 'pumpFanout',
      startTime: '10s',
    },
  },
  thresholds: {
    realtime_message_latency_ms: [`p(95)<${THRESHOLDS.realtimeMessageP95Ms}`],
    ambient_fanout_latency_ms: [`p(95)<${THRESHOLDS.ambientFanoutP95Ms}`],
    checks: ['rate>0.90'],
  },
};

function broadcastPayload(msg) {
  const p = msg.payload;
  if (!p) return null;
  if (typeof p.sent_at_ms === 'number') return p;
  if (p.payload && typeof p.payload.sent_at_ms === 'number') return p.payload;
  return null;
}

export function tripSubscribe() {
  const trip = fixture.trips[(__VU - 1) % fixture.trips.length];
  if (!trip?.id) {
    sleep(1);
    return;
  }
  const jwt = __VU % 2 === 0 ? trip.driver_jwt : trip.rider_jwt;
  const topic = `trip:${trip.id}`;
  const url = realtimeWsUrl(baseUrl, anonKey);

  ws.connect(url, {}, (socket) => {
    socket.on('open', () => {
      socket.send(phxJoin(topic, jwt, __VU));
    });

    socket.on('message', (raw) => {
      let msg;
      try {
        msg = JSON.parse(raw);
      } catch {
        return;
      }
      if (msg.event === 'broadcast') {
        const payload = broadcastPayload(msg);
        if (payload?.sent_at_ms) {
          tripEvents.add(1);
          realtimeMsgLatency.add(Date.now() - Number(payload.sent_at_ms));
        }
      }
    });

    socket.setTimeout(() => socket.close(), durationMs() + 15000);
  });
}

export function pumpTripBroadcast() {
  const trip = fixture.trips[__ITER % fixture.trips.length];
  if (!trip?.id) return;
  const sentAt = Date.now();
  const res = broadcastTripLocTest(baseUrl, serviceKey, trip.id, sentAt);
  check(res, { 'trip loc broadcast ok': (r) => r.status === 200 || r.status === 202 });
}

export function pumpFanout() {
  const started = Date.now();
  const res = fanoutMode === 'edge'
    ? triggerPresenceFanout(functionsUrl, serviceKey, fixture.city_id)
    : triggerPresenceFanoutDirect(baseUrl, serviceKey, fixture.city_id);
  check(res, { 'presence-fanout ok': (r) => r.status === 200 });
  fanoutLatency.add(Date.now() - started);
}

function durationMs() {
  const match = /^(\d+)(m|s|h)$/.exec(duration);
  if (!match) return 600_000;
  const n = Number(match[1]);
  if (match[2] === 'h') return n * 3_600_000;
  if (match[2] === 'm') return n * 60_000;
  return n * 1000;
}

export function handleSummary(data) {
  const label = __ENV.RUN_LABEL || 'local';
  const outDir = __ENV.LOAD_RESULTS_DIR || 'results';
  const scaleFactor = Number(__ENV.SCALE_FACTOR) || 1;
  const lines = [
    '',
    '=== TS-OPS-03 trip:* realtime scale (k6) ===',
    `target_trip_subscriber_vus=${tripSubscriberVus} trip_broadcast_rate=${tripBroadcastRate}/s`,
    `duration=${duration} scale_factor=${scaleFactor}`,
  ];
  for (const [name, metric] of Object.entries(data.metrics || {})) {
    if (!metric.values) continue;
    const p95 = metric.values['p(95)'];
    if (p95 !== undefined) {
      lines.push(`${name}: p95=${p95.toFixed(2)}`);
    }
  }
  return {
    stdout: lines.join('\n') + '\n',
    [`${outDir}/ts-ops-03-${label}.json`]: JSON.stringify(data, null, 2),
  };
}
