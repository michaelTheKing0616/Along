import { discreteFrechetM } from './frechet.js';
import { clusterPoints } from './spatial-cluster.js';
import type { GeoJsonLineString } from './types.js';
import type { JobRunRecord } from './map-match.js';

export type RouteInferenceJobConfig = {
  minTrips: number;
  frechetM: number;
  minConfidence: number;
};

export type MatchedTraceForInference = {
  tripId: string;
  cityId: string;
  modeCode: string;
  confidence: number;
  geometryGeoJson: GeoJsonLineString;
  matchMeta: Record<string, unknown>;
};

export type RouteInferenceCandidateInsert = {
  cityId: string;
  modeCode: string;
  geometryGeoJson: GeoJsonLineString;
  originLng: number;
  originLat: number;
  destinationLng: number;
  destinationLat: number;
  supportingTripCount: number;
  tripIds: string[];
};

export type RouteInferenceStats = {
  traces_examined: number;
  groups_found: number;
  candidates_inserted: number;
  skipped_low_confidence: number;
  skipped_below_min_trips: number;
  skipped_frechet: number;
};

export type RouteInferenceDb = {
  beginJobRun(jobName: string, params?: Record<string, unknown>): Promise<JobRunRecord>;
  finishJobRun(
    jobRunId: string,
    status: 'succeeded' | 'failed',
    stats?: Record<string, unknown>,
    error?: string,
  ): Promise<void>;
  loadRouteInferenceConfig(cityId?: string): Promise<RouteInferenceJobConfig>;
  listMatchedTracesForInference(minConfidence: number): Promise<MatchedTraceForInference[]>;
  insertRouteInferenceCandidates(
    candidates: RouteInferenceCandidateInsert[],
  ): Promise<number>;
};

type TraceBucket = {
  cityId: string;
  modeCode: string;
  originCluster: number;
  destinationCluster: number;
  traces: MatchedTraceForInference[];
};

function endpoint(trace: MatchedTraceForInference): {
  origin: [number, number];
  destination: [number, number];
} {
  const coords = trace.geometryGeoJson.coordinates;
  const origin = coords[0]!;
  const destination = coords[coords.length - 1]!;
  return { origin, destination };
}

function bucketKey(bucket: TraceBucket): string {
  return [
    bucket.cityId,
    bucket.modeCode,
    bucket.originCluster,
    bucket.destinationCluster,
  ].join('|');
}

/**
 * Cluster matched driver traces by (mode, origin cluster, destination cluster).
 * doc 04 §15 — FM27: input must already be map-matched traces only.
 */
export function clusterTracesForRouteInference(
  traces: MatchedTraceForInference[],
  config: RouteInferenceJobConfig,
): RouteInferenceCandidateInsert[] {
  if (traces.length === 0) return [];

  const origins = traces.map((trace) => {
    const { origin } = endpoint(trace);
    return { id: trace.tripId, lng: origin[0], lat: origin[1] };
  });
  const destinations = traces.map((trace) => {
    const { destination } = endpoint(trace);
    return { id: trace.tripId, lng: destination[0], lat: destination[1] };
  });

  const originClusters = clusterPoints(origins, config.frechetM);
  const destinationClusters = clusterPoints(destinations, config.frechetM);

  const buckets = new Map<string, TraceBucket>();
  for (const trace of traces) {
    const originCluster = originClusters.get(trace.tripId);
    const destinationCluster = destinationClusters.get(trace.tripId);
    if (originCluster === undefined || destinationCluster === undefined) continue;

    const bucket: TraceBucket = {
      cityId: trace.cityId,
      modeCode: trace.modeCode,
      originCluster,
      destinationCluster,
      traces: [],
    };
    const key = bucketKey(bucket);
    const existing = buckets.get(key);
    if (existing) {
      existing.traces.push(trace);
    } else {
      bucket.traces = [trace];
      buckets.set(key, bucket);
    }
  }

  const candidates: RouteInferenceCandidateInsert[] = [];

  for (const bucket of buckets.values()) {
    if (bucket.traces.length < config.minTrips) continue;

    const reference = bucket.traces[0]!;
    const coherent = bucket.traces.filter(
      (trace) =>
        discreteFrechetM(
          reference.geometryGeoJson.coordinates,
          trace.geometryGeoJson.coordinates,
        ) <= config.frechetM,
    );
    if (coherent.length < config.minTrips) continue;

    const { origin, destination } = endpoint(reference);
    candidates.push({
      cityId: bucket.cityId,
      modeCode: bucket.modeCode,
      geometryGeoJson: reference.geometryGeoJson,
      originLng: origin[0],
      originLat: origin[1],
      destinationLng: destination[0],
      destinationLat: destination[1],
      supportingTripCount: coherent.length,
      tripIds: coherent.map((trace) => trace.tripId),
    });
  }

  return candidates;
}

export async function runRouteInferenceJob(
  db: RouteInferenceDb,
): Promise<RouteInferenceStats> {
  const config = await db.loadRouteInferenceConfig();
  const jobRun = await db.beginJobRun('route-inference', {
    min_trips: config.minTrips,
    frechet_m: config.frechetM,
    min_confidence: config.minConfidence,
  });

  const stats: RouteInferenceStats = {
    traces_examined: 0,
    groups_found: 0,
    candidates_inserted: 0,
    skipped_low_confidence: 0,
    skipped_below_min_trips: 0,
    skipped_frechet: 0,
  };

  try {
    const traces = await db.listMatchedTracesForInference(config.minConfidence);
    const eligible: MatchedTraceForInference[] = [];

    for (const trace of traces) {
      stats.traces_examined += 1;
      if (trace.confidence < config.minConfidence) {
        stats.skipped_low_confidence += 1;
        continue;
      }
      if (trace.geometryGeoJson.coordinates.length < 2) continue;
      eligible.push(trace);
    }

    const candidates = clusterTracesForRouteInference(eligible, config);
    stats.groups_found = candidates.length;
    stats.candidates_inserted = await db.insertRouteInferenceCandidates(candidates);
    await db.finishJobRun(jobRun.id, 'succeeded', stats);
    return stats;
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    await db.finishJobRun(jobRun.id, 'failed', stats, message);
    throw err;
  }
}
