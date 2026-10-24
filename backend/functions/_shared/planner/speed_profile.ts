import type { SupabaseClient } from '@supabase/supabase-js';
import type { PlannerCfg } from '../types.ts';

/**
 * Historical segment speed calibration for in_vehicle_time_estimate_s (doc 04 §4.4 / §15).
 *
 * Fallback order:
 * 1. Live 10-minute map-matched median — used by the in-trip estimator
 *    (`_shared/eta/estimate.ts`). A quote has no trip yet, so planner calibration
 *    still starts at the hour profile.
 * 2. segment_speed_profiles for matching hour/dow when route_leg.segment_keys are present.
 * 3. Unchanged base in_vehicle_time_estimate_s (seeded graph or OSRM × shared_vehicle_factor).
 */

export type SegmentSpeedProfile = {
  segment_key: string;
  median_speed_mps: number;
  sample_count: number;
};

/** doc 02 §12 / doc 04 §4.4: 0 = Mon–Fri, 1 = Sat–Sun */
export function dowBucket(date: Date, timeZone = 'UTC'): 0 | 1 {
  const weekday = new Intl.DateTimeFormat('en-US', {
    timeZone,
    weekday: 'short',
  }).format(date);
  return weekday === 'Sat' || weekday === 'Sun' ? 1 : 0;
}

export function hourBucket(date: Date, timeZone = 'UTC'): number {
  const hour = Number(
    new Intl.DateTimeFormat('en-US', {
      timeZone,
      hour: 'numeric',
      hour12: false,
    }).format(date),
  );
  return hour === 24 ? 0 : hour;
}

/** Scale in_vehicle_s when historical segment speed profiles are available (doc 04 §4.4). */
export function calibrateInVehicleS(
  baseInVehicleS: number,
  profiles: SegmentSpeedProfile[],
  cfg: Pick<PlannerCfg, 'baselineSpeedMps' | 'speedProfileMinSamples'>,
): number {
  if (baseInVehicleS <= 0 || profiles.length === 0) return baseInVehicleS;

  const qualifying = profiles.filter(
    (p) =>
      p.sample_count >= cfg.speedProfileMinSamples &&
      Number.isFinite(p.median_speed_mps) &&
      p.median_speed_mps > 0,
  );
  if (qualifying.length === 0) return baseInVehicleS;

  const avgMedian =
    qualifying.reduce((sum, p) => sum + p.median_speed_mps, 0) / qualifying.length;
  if (avgMedian <= 0 || cfg.baselineSpeedMps <= 0) return baseInVehicleS;

  return Math.max(1, Math.round(baseInVehicleS * (cfg.baselineSpeedMps / avgMedian)));
}

export async function fetchSegmentSpeedProfiles(
  service: SupabaseClient,
  input: {
    cityId: string;
    segmentKeys: string[];
    at?: Date;
    timeZone?: string;
  },
): Promise<SegmentSpeedProfile[]> {
  const keys = [...new Set(input.segmentKeys.filter(Boolean))];
  if (keys.length === 0) return [];

  const at = input.at ?? new Date();
  const tz = input.timeZone ?? 'UTC';
  const { data, error } = await service.rpc('segment_speed_profiles_lookup', {
    p_city_id: input.cityId,
    p_segment_keys: keys,
    p_dow_bucket: dowBucket(at, tz),
    p_hour_bucket: hourBucket(at, tz),
  });
  if (error) throw error;

  return ((data ?? []) as Array<Record<string, unknown>>).map((row) => ({
    segment_key: String(row.segment_key),
    median_speed_mps: Number(row.median_speed_mps),
    sample_count: Number(row.sample_count),
  }));
}

export async function calibrateInVehicleWithProfiles(
  service: SupabaseClient,
  input: {
    cityId: string;
    baseInVehicleS: number;
    segmentKeys: string[] | undefined;
    cfg: PlannerCfg;
    at?: Date;
    timeZone?: string;
  },
): Promise<number> {
  if (!input.segmentKeys?.length || input.baseInVehicleS <= 0) {
    return input.baseInVehicleS;
  }

  const profiles = await fetchSegmentSpeedProfiles(service, {
    cityId: input.cityId,
    segmentKeys: input.segmentKeys,
    at: input.at,
    timeZone: input.timeZone,
  });
  return calibrateInVehicleS(input.baseInVehicleS, profiles, input.cfg);
}

export async function resolveSegmentKeys(
  service: SupabaseClient,
  input: {
    routeId: string | null | undefined;
    fromStageId: string;
    toStageId: string;
    segmentKeys?: string[];
  },
): Promise<string[] | undefined> {
  if (input.segmentKeys?.length) return input.segmentKeys;
  if (!input.routeId) return undefined;

  const { data, error } = await service.rpc('route_leg_segment_keys', {
    p_route_id: input.routeId,
    p_from_stage_id: input.fromStageId,
    p_to_stage_id: input.toStageId,
  });
  if (error) throw error;

  const keys = (data ?? []) as string[];
  return keys.length > 0 ? keys : undefined;
}
