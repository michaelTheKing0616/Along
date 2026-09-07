import { check, sleep } from 'k6';
import { Counter, Trend } from 'k6/metrics';
import { FULL_CITY, THRESHOLDS } from './thresholds.js';
import { planTripBody } from './lib/fixtures.js';
import { invokeEdgeFunction, rpc } from './lib/supabase.js';

const planTripLatency = new Trend('plan_trip_latency_ms', true);
const presencePingLatency = new Trend('presence_ping_latency_ms', true);
const planTripOk = new Counter('plan_trip_ok');
const presencePingOk = new Counter('presence_ping_ok');

const fixture = JSON.parse(open(__ENV.LOAD_TOKENS_FILE || `${__ENV.PWD}/.tokens.json`));

const baseUrl = __ENV.SUPABASE_URL || 'http://127.0.0.1:54321';
const anonKey = __ENV.SUPABASE_ANON_KEY;
const functionsUrl = __ENV.SUPABASE_FUNCTIONS_URL || `${baseUrl}/functions/v1`;

const planTripRate = Number(__ENV.PLAN_TRIP_RATE) || FULL_CITY.planTripRps;
const presencePingRate = Number(__ENV.PRESENCE_PING_RATE) || FULL_CITY.presencePingRps;
const duration = __ENV.DURATION || FULL_CITY.duration;

export const options = {
  scenarios: {
    plan_trip_rps: {
      executor: 'constant-arrival-rate',
      rate: planTripRate,
      timeUnit: '1s',
      duration,
      preAllocatedVUs: Math.min(planTripRate, 200),
      maxVUs: Math.max(planTripRate * 2, 400),
      exec: 'planTripOnce',
    },
    presence_ping_rps: {
      executor: 'constant-arrival-rate',
      rate: presencePingRate,
      timeUnit: '1s',
      duration,
      preAllocatedVUs: Math.min(Math.ceil(presencePingRate / 5), 500),
      maxVUs: Math.max(presencePingRate, 2000),
      exec: 'presencePingOnce',
      startTime: '5s',
    },
  },
  thresholds: {
    plan_trip_latency_ms: [`p(95)<${THRESHOLDS.planTripP95Ms}`],
    presence_ping_latency_ms: [`p(95)<${THRESHOLDS.presencePingP95Ms}`],
    'http_req_failed{rpc:plan-trip}': ['rate<0.02'],
    'http_req_failed{rpc:presence_ping}': ['rate<0.02'],
    checks: ['rate>0.95'],
  },
};

function pingBody(vu) {
  const baseLat = 11.061 + (vu % 100) * 0.0001;
  const baseLng = 7.701 + (vu % 100) * 0.0001;
  return {
    p_location: { lat: baseLat, lng: baseLng },
    p_heading: 90,
    p_speed_mps: 4.5,
    p_accuracy_m: 10,
    p_seats_available: 4,
  };
}

export function planTripOnce() {
  const rider = fixture.riders[(__VU - 1) % fixture.riders.length];
  const body = planTripBody(rider.jwt, __VU, __ITER);
  const res = invokeEdgeFunction(functionsUrl, anonKey, rider.jwt, 'plan-trip', body);
  planTripLatency.add(res.timings.duration);
  const ok = check(res, {
    'plan-trip status 200': (r) => r.status === 200,
    'plan-trip has data': (r) => {
      if (r.status !== 200) return false;
      const parsed = r.json();
      return parsed && (parsed.data !== undefined || parsed.candidates !== undefined);
    },
  });
  if (ok) planTripOk.add(1);
}

export function presencePingOnce() {
  const driver = fixture.drivers[(__VU - 1) % fixture.drivers.length];
  const res = rpc(baseUrl, anonKey, driver.jwt, 'presence_ping', pingBody(__VU));
  presencePingLatency.add(res.timings.duration);
  const ok = check(res, {
    'presence_ping status 200': (r) => r.status === 200,
    'presence_ping accepted or throttled': (r) => {
      if (r.status !== 200) return false;
      const body = r.json();
      return body && typeof body.accepted === 'boolean';
    },
  });
  if (ok) presencePingOk.add(1);
  // Throttle-aware spacing when arrival rate exceeds server min interval.
  sleep(0.05);
}

export function handleSummary(data) {
  const label = __ENV.RUN_LABEL || 'local';
  const outDir = __ENV.LOAD_RESULTS_DIR || 'results';
  const scaleFactor = Number(__ENV.SCALE_FACTOR) || 1;
  const lines = [
    '',
    '=== TS-OPS-02 plan-trip + presence mix (k6) ===',
    `target_plan_trip_rps=${planTripRate} target_presence_ping_rps=${presencePingRate}`,
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
    [`${outDir}/ts-ops-02-${label}.json`]: JSON.stringify(data, null, 2),
  };
}
