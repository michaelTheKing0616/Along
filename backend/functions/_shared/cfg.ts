import type { SupabaseClient } from '@supabase/supabase-js';
import type { PlacesCfg, PlannerCfg } from './types.ts';

type CfgRow = { key: string; value: unknown };

function parseNum(raw: unknown, fallback: number): number {
  if (typeof raw === 'number') return raw;
  if (typeof raw === 'string') return Number(raw);
  return fallback;
}

function parseJson<T>(raw: unknown, fallback: T): T {
  if (typeof raw === 'string') {
    try {
      return JSON.parse(raw) as T;
    } catch {
      return fallback;
    }
  }
  if (raw && typeof raw === 'object') return raw as T;
  return fallback;
}

async function cfgValue(
  client: SupabaseClient,
  key: string,
  cityId: string | null,
): Promise<unknown> {
  const { data, error } = await client.rpc('cfg', { p_key: key, p_city: cityId });
  if (error) throw error;
  return data;
}

export async function loadPlannerCfg(
  client: SupabaseClient,
  cityId: string,
): Promise<PlannerCfg> {
  const keys = [
    'planner.max_candidates',
    'planner.walk_speed_mps',
    'planner.shared_vehicle_factor',
    'planner.default_wait_s',
    'planner.direct_viability_factor',
    'planner.direct_viability_slack_s',
    'planner.baseline_speed_mps',
    'planner.speed_profile_min_samples',
    'planner.recommended_weights',
    'planner.strenuous_weights',
    'load.warn_capacities',
  ] as const;

  const values = await Promise.all(
    keys.map((k) => cfgValue(client, k, cityId)),
  );

  return {
    maxCandidates: parseNum(values[0], 12),
    walkSpeedMps: parseNum(values[1], 1.25),
    sharedVehicleFactor: parseNum(values[2], 1.25),
    defaultWaitS: parseNum(values[3], 300),
    directViabilityFactor: parseNum(values[4], 1.5),
    directViabilitySlackS: parseNum(values[5], 300),
    baselineSpeedMps: parseNum(values[6], 8.33),
    speedProfileMinSamples: parseNum(values[7], 8),
    recommendedWeights: parseJson(values[8], { fare: 0.4, time: 0.4, strenuous: 0.2 }),
    strenuousWeights: parseJson(values[9], {
      transfer: 1,
      walk_per_100m: 0.25,
      mode: 0.5,
    }),
    warnCapacities: parseJson(values[10], {
      small: ['none'],
      medium: ['none', 'small'],
      large: ['none', 'small', 'medium'],
    }),
  };
}

export async function loadPlacesCfg(
  client: SupabaseClient,
  cityId: string,
): Promise<PlacesCfg> {
  const keys = [
    'places.search_radius_m',
    'places.trigram_min_similarity',
    'places.photon_timeout_ms',
  ] as const;

  const values = await Promise.all(
    keys.map((k) => cfgValue(client, k, cityId)),
  );

  return {
    searchRadiusM: parseNum(values[0], 5000),
    trigramMinSimilarity: parseNum(values[1], 0.2),
    photonTimeoutMs: parseNum(values[2], 800),
  };
}

export async function cityForPoint(
  client: SupabaseClient,
  lat: number,
  lng: number,
): Promise<string | null> {
  const { data, error } = await client.rpc('city_for_lat_lng', { p_lat: lat, p_lng: lng });
  if (error) throw error;
  return data as string | null;
}

export async function loadPresenceFanoutCfg(
  client: SupabaseClient,
  cityId: string | null = null,
): Promise<{ fanoutIntervalS: number; fanoutRadiusM: number }> {
  const keys = ['presence.fanout_interval_s', 'presence.fanout_radius_m'] as const;
  const values = await Promise.all(
    keys.map((k) => cfgValue(client, k, cityId)),
  );

  return {
    fanoutIntervalS: parseNum(values[0], 10),
    fanoutRadiusM: parseNum(values[1], 3000),
  };
}

export async function loadDispatchCfg(
  client: SupabaseClient,
  cityId: string,
): Promise<{ requestTtlS: number }> {
  const ttl = await cfgValue(client, 'dispatch.request_ttl_s', cityId);
  return { requestTtlS: parseNum(ttl, 25) };
}

export type CacheCfg = {
  planTripTtlS: number;
  placesTtlS: number;
  graphBundleTtlS: number;
  graphBundleMaxParks: number;
  graphBundleMaxStages: number;
  graphBundleMaxLegs: number;
};

export async function loadCacheCfg(
  client: SupabaseClient,
  cityId: string | null = null,
): Promise<CacheCfg> {
  const keys = [
    'cache.plan_trip_ttl_s',
    'cache.places_ttl_s',
    'cache.graph_bundle_ttl_s',
    'cache.graph_bundle_max_parks',
    'cache.graph_bundle_max_stages',
    'cache.graph_bundle_max_legs',
  ] as const;

  const values = await Promise.all(
    keys.map((k) => cfgValue(client, k, cityId)),
  );

  return {
    planTripTtlS: parseNum(values[0], 60),
    placesTtlS: parseNum(values[1], 86400),
    graphBundleTtlS: parseNum(values[2], 3600),
    graphBundleMaxParks: parseNum(values[3], 500),
    graphBundleMaxStages: parseNum(values[4], 2000),
    graphBundleMaxLegs: parseNum(values[5], 5000),
  };
}

/** Unused export kept for cfg module completeness — satisfies lint for CfgRow. */
export type { CfgRow };
