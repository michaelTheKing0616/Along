import ws from 'k6/ws';
import { check, sleep } from 'k6';
import { Counter, Trend } from 'k6/metrics';
import { THRESHOLDS } from './thresholds.js';
import {
  phxJoin,
  realtimeWsUrl,
  rpc,
  triggerPresenceFanout,
  triggerPresenceFanoutDirect,
} from './lib/supabase.js';

const pingLatency = new Trend('presence_ping_latency_ms', true);
const fanoutLatency = new Trend('ambient_fanout_latency_ms', true);
const realtimeMsgLatency = new Trend('realtime_message_latency_ms', true);
const cellsEvents = new Counter('ambient_cells_events');
const tripEvents = new Counter('trip_broadcast_events');

const fixture = JSON.parse(open(__ENV.LOAD_TOKENS_FILE || `${__ENV.PWD}/.tokens.json`));

const baseUrl = __ENV.SUPABASE_URL || 'http://127.0.0.1:54321';
const anonKey = __ENV.SUPABASE_ANON_KEY;
const serviceKey = __ENV.SUPABASE_SERVICE_ROLE_KEY;
const functionsUrl = __ENV.SUPABASE_FUNCTIONS_URL || `${baseUrl}/functions/v1`;
const fanoutMode = __ENV.FANOUT_MODE || 'direct';
const minPingGapMs = (Number(__ENV.PRESENCE_PING_MIN_INTERVAL_S) || THRESHOLDS.presencePingMinIntervalS) * 1000 + 200;

export const options = {
  scenarios: {
    presence_ping: {
      executor: 'constant-vus',
      vus: Number(__ENV.DRIVER_VUS) || 10,
      duration: __ENV.DURATION || '2m',
      exec: 'presencePing',
    },
    ambient_subscribers: {
      executor: 'constant-vus',
      vus: Number(__ENV.AMBIENT_SUBSCRIBER_VUS) || 10,
      duration: __ENV.DURATION || '2m',
      exec: 'ambientSubscribe',
      startTime: '5s',
    },
    trip_subscribers: {
      executor: 'constant-vus',
      vus: Number(__ENV.TRIP_SUBSCRIBER_VUS) || Math.min(5, fixture.trips.length || 3),
      duration: __ENV.DURATION || '2m',
      exec: 'tripSubscribe',
      startTime: '5s',
    },
    fanout_pump: {
      executor: 'constant-arrival-rate',
      rate: 1,
      timeUnit: `${THRESHOLDS.presenceFanoutIntervalS}s`,
      duration: __ENV.DURATION || '2m',
      preAllocatedVUs: 1,
      maxVUs: 1,
      exec: 'pumpFanout',
      startTime: '10s',
    },
  },
  thresholds: {
    presence_ping_latency_ms: [`p(95)<${THRESHOLDS.presencePingP95Ms}`],
    ambient_fanout_latency_ms: [`p(95)<${THRESHOLDS.ambientFanoutP95Ms}`],
    realtime_message_latency_ms: [`p(95)<${THRESHOLDS.realtimeMessageP95Ms}`],
    'http_req_failed{rpc:presence_ping}': ['rate<0.01'],
    checks: ['rate>0.95'],
  },
};

function pingBody(vu) {
  const baseLat = 11.061 + vu * 0.0001;
  const baseLng = 7.701 + vu * 0.0001;
  return {
    p_location: { lat: baseLat, lng: baseLng },
    p_heading: 90,
    p_speed_mps: 4.5,
    p_accuracy_m: 10,
    p_seats_available: 4,
  };
}

export function presencePing() {
  const driver = fixture.drivers[(__VU - 1) % fixture.drivers.length];
  const res = rpc(baseUrl, anonKey, driver.jwt, 'presence_ping', pingBody(__VU));
  pingLatency.add(res.timings.duration);
  check(res, {
    'presence_ping status 200': (r) => r.status === 200,
    'presence_ping accepted or throttled': (r) => {
      if (r.status !== 200) return false;
      const body = r.json();
      return body && typeof body.accepted === 'boolean';
    },
  });
  sleep(minPingGapMs / 1000);
}

export function ambientSubscribe() {
  const rider = fixture.riders[(__VU - 1) % fixture.riders.length];
  const topic = `ambient:${fixture.city_slug}:${fixture.geohash5}`;
  const url = realtimeWsUrl(baseUrl, anonKey);

  ws.connect(url, {}, (socket) => {
    socket.on('open', () => {
      socket.send(phxJoin(topic, rider.jwt, __VU));
    });

    socket.on('message', (raw) => {
      let msg;
      try {
        msg = JSON.parse(raw);
      } catch {
        return;
      }
      if (msg.event === 'broadcast' && msg.payload?.event === 'cells') {
        cellsEvents.add(1);
        realtimeMsgLatency.add(1);
      }
    });

    socket.setTimeout(() => socket.close(), 115000);
  });
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
        tripEvents.add(1);
        realtimeMsgLatency.add(1);
      }
    });

    socket.setTimeout(() => socket.close(), 115000);
  });
}

export function pumpFanout() {
  const started = Date.now();
  const res = fanoutMode === 'edge'
    ? triggerPresenceFanout(functionsUrl, serviceKey, fixture.city_id)
    : triggerPresenceFanoutDirect(baseUrl, serviceKey, fixture.city_id);
  check(res, { 'presence-fanout ok': (r) => r.status === 200 });
  fanoutLatency.add(Date.now() - started);
}

export function handleSummary(data) {
  const label = __ENV.RUN_LABEL || 'local';
  const outDir = __ENV.LOAD_RESULTS_DIR || 'results';
  const lines = ['', '=== P3-E-01 presence/realtime pilot (k6) ==='];
  for (const [name, metric] of Object.entries(data.metrics || {})) {
    if (!metric.values) continue;
    const p95 = metric.values['p(95)'];
    if (p95 !== undefined) {
      lines.push(`${name}: p95=${p95.toFixed(2)}`);
    }
  }
  return {
    stdout: lines.join('\n') + '\n',
    [`${outDir}/pilot-${label}.json`]: JSON.stringify(data, null, 2),
  };
}
