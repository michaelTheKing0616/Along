import http from 'k6/http';

/** POST /rest/v1/rpc/{name} with bearer JWT. */
export function rpc(baseUrl, anonKey, jwt, fn, body) {
  const url = `${baseUrl.replace(/\/$/, '')}/rest/v1/rpc/${fn}`;
  const res = http.post(url, JSON.stringify(body), {
    headers: {
      apikey: anonKey,
      Authorization: `Bearer ${jwt}`,
      'Content-Type': 'application/json',
      Prefer: 'return=representation',
    },
    tags: { rpc: fn, name: fn },
  });
  return res;
}

/** Invoke presence-fanout Edge Function (service role). */
export function triggerPresenceFanout(functionsUrl, serviceKey, cityId) {
  const url = `${functionsUrl.replace(/\/$/, '')}/presence-fanout`;
  return http.post(
    url,
    JSON.stringify(cityId ? { city_id: cityId } : {}),
    {
      headers: {
        apikey: serviceKey,
        Authorization: `Bearer ${serviceKey}`,
        'Content-Type': 'application/json',
      },
      tags: { rpc: 'presence-fanout', name: 'presence-fanout' },
    },
  );
}

function serviceHeaders(baseUrl, serviceKey) {
  return {
    apikey: serviceKey,
    Authorization: `Bearer ${serviceKey}`,
    'Content-Type': 'application/json',
  };
}

/**
 * Local/staging fallback: same steps as presence-fanout Edge Function via REST + RPC.
 * Use when Edge runtime is unavailable (local `supabase start` without functions).
 */
export function triggerPresenceFanoutDirect(baseUrl, serviceKey, cityId) {
  const root = baseUrl.replace(/\/$/, '');
  const targetsRes = http.post(
    `${root}/rest/v1/rpc/presence_fanout_targets`,
    '{}',
    { headers: serviceHeaders(baseUrl, serviceKey), tags: { rpc: 'presence_fanout_targets', name: 'presence-fanout-direct' } },
  );
  if (targetsRes.status !== 200) {
    return targetsRes;
  }

  const targets = targetsRes.json();
  const filtered = cityId ? targets.filter((t) => t.city_id === cityId) : targets;
  let published = 0;

  for (const target of filtered) {
    const ambientRes = http.post(
      `${root}/rest/v1/rpc/ambient_vehicles`,
      JSON.stringify({
        p_lat: target.centroid_lat,
        p_lng: target.centroid_lng,
        p_radius_m: target.radius_m,
      }),
      { headers: serviceHeaders(baseUrl, serviceKey), tags: { rpc: 'ambient_vehicles', name: 'presence-fanout-direct' } },
    );
    if (ambientRes.status !== 200) {
      continue;
    }
    const ambient = ambientRes.json();
    const topic = `ambient:${target.city_slug}:${target.geohash5}`;
    const broadcastRes = http.post(
      `${root}/realtime/v1/api/broadcast`,
      JSON.stringify({
        messages: [{
          topic,
          event: 'cells',
          payload: {
            type: 'cells',
            cells: ambient.cells ?? [],
            as_of: ambient.as_of ?? new Date().toISOString(),
          },
          private: true,
        }],
      }),
      { headers: serviceHeaders(baseUrl, serviceKey), tags: { rpc: 'realtime-broadcast', name: 'presence-fanout-direct' } },
    );
    if (broadcastRes.status === 200 || broadcastRes.status === 202) {
      published += 1;
    }
  }

  return {
    status: published > 0 ? 200 : 502,
    timings: targetsRes.timings,
    json: () => ({ data: { published } }),
  };
}

/** POST /functions/v1/{slug} with bearer JWT. */
export function invokeEdgeFunction(functionsUrl, anonKey, jwt, slug, body) {
  const url = `${functionsUrl.replace(/\/$/, '')}/${slug}`;
  return http.post(url, JSON.stringify(body), {
    headers: {
      apikey: anonKey,
      Authorization: `Bearer ${jwt}`,
      'Content-Type': 'application/json',
    },
    tags: { rpc: slug, name: slug },
  });
}

/**
 * Service-role trip loc broadcast for TS-OPS-03 latency measurement.
 * Embeds sent_at_ms (load-test only) so subscribers can compute delivery latency.
 */
export function broadcastTripLocTest(baseUrl, serviceKey, tripId, sentAtMs) {
  const root = baseUrl.replace(/\/$/, '');
  const lat = 11.061 + (sentAtMs % 1000) * 0.00001;
  const lng = 7.701 + (sentAtMs % 1000) * 0.00001;
  return http.post(
    `${root}/realtime/v1/api/broadcast`,
    JSON.stringify({
      messages: [{
        topic: `trip:${tripId}`,
        event: 'loc',
        payload: {
          type: 'loc',
          actor: 'driver',
          lat,
          lng,
          heading: 90,
          speed_mps: 4.5,
          ts: new Date(sentAtMs).toISOString(),
          sent_at_ms: sentAtMs,
        },
        private: true,
      }],
    }),
    {
      headers: serviceHeaders(baseUrl, serviceKey),
      tags: { rpc: 'trip-loc-broadcast', name: 'trip-loc-broadcast' },
    },
  );
}

/** Build Supabase Realtime WebSocket URL (Broadcast private channels). */
export function realtimeWsUrl(baseUrl, anonKey) {
  const wsBase = baseUrl.replace(/^http/, 'ws');
  return `${wsBase}/realtime/v1/websocket?apikey=${encodeURIComponent(anonKey)}&vsn=1.0.0`;
}

/** Phoenix join payload for a private Broadcast channel topic. */
export function phxJoin(topic, jwt, ref) {
  return JSON.stringify({
    topic: `realtime:${topic}`,
    event: 'phx_join',
    payload: {
      config: { broadcast: { self: false, ack: false }, private: true },
      access_token: jwt,
    },
    ref: String(ref),
  });
}
