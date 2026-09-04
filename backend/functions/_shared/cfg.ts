import type { SupabaseClient } from '@supabase/supabase-js';
import type { PlannerCfg } from '../types.ts';

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
  cityId: string,
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
    recommendedWeights: parseJson(values[6], { fare: 0.4, time: 0.4, strenuous: 0.2 }),
    strenuousWeights: parseJson(values[7], {
      transfer: 1,
      walk_per_100m: 0.25,
      mode: 0.5,
    }),
    warnCapacities: parseJson(values[8], {
      small: ['none'],
      medium: ['none', 'small'],
      large: ['none', 'small', 'medium'],
    }),
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

/** Unused export kept for cfg module completeness — satisfies lint for CfgRow. */
export type { CfgRow };
