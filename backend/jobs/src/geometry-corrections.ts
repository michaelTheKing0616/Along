import { haversineM } from './frechet.js';
import type { GeoJsonLineString } from './types.js';
import type { JobRunRecord } from './map-match.js';

export type GeometryCorrectionsJobConfig = {
  minSupportingTraces: number;
  clusterM: number;
  minConfidence: number;
};

export type MatchedTraceForGeometry = {
  tripId: string;
  cityId: string;
  confidence: number;
  matchMeta: Record<string, unknown>;
};

export type GeometryCorrectionInsert = {
  cityId: string;
  geometryGeoJson: GeoJsonLineString;
  supportingTraceCount: number;
  tripIds: string[];
};

export type GeometryCorrectionsStats = {
  traces_examined: number;
  segments_extracted: number;
  clusters_found: number;
  corrections_inserted: number;
};

export type GeometryCorrectionsDb = {
  beginJobRun(jobName: string, params?: Record<string, unknown>): Promise<JobRunRecord>;
  finishJobRun(
    jobRunId: string,
    status: 'succeeded' | 'failed',
    stats?: Record<string, unknown>,
    error?: string,
  ): Promise<void>;
  loadGeometryCorrectionsConfig(cityId?: string): Promise<GeometryCorrectionsJobConfig>;
  listMatchedTracesForGeometryCorrections(): Promise<MatchedTraceForGeometry[]>;
  insertRoadGeometryCorrections(
    corrections: GeometryCorrectionInsert[],
  ): Promise<number>;
};

type LowConfidenceSegment = {
  tripId: string;
  cityId: string;
  coordinates: [number, number][];
  confidence: number;
};

function parseSegment(raw: unknown): {
  coordinates: [number, number][];
  confidence: number;
} | null {
  if (!raw || typeof raw !== 'object') return null;
  const row = raw as Record<string, unknown>;
  const confidence = Number(row.confidence ?? row.segment_confidence);
  const lng = row.lng ?? row.lon;
  const lat = row.lat;
  if (Number.isFinite(confidence) && Number.isFinite(Number(lng)) && Number.isFinite(Number(lat))) {
    return {
      coordinates: [[Number(lng), Number(lat)]],
      confidence,
    };
  }

  const geometry = row.geometry ?? row.line;
  if (geometry && typeof geometry === 'object') {
    const geo = geometry as GeoJsonLineString;
    if (geo.type === 'LineString' && Array.isArray(geo.coordinates) && geo.coordinates.length >= 1) {
      return {
        coordinates: geo.coordinates as [number, number][],
        confidence: Number.isFinite(confidence) ? confidence : 0,
      };
    }
  }

  return null;
}

/** Extract per-segment low-confidence divergences from matched_traces match_meta. */
export function extractLowConfidenceSegments(
  traces: MatchedTraceForGeometry[],
  minConfidence: number,
): LowConfidenceSegment[] {
  const segments: LowConfidenceSegment[] = [];

  for (const trace of traces) {
    const meta = trace.matchMeta ?? {};
    const rawSegments =
      meta.low_confidence_segments ??
      meta.divergence_segments ??
      meta.geometry_divergence ??
      [];
    if (!Array.isArray(rawSegments)) continue;

    for (const raw of rawSegments) {
      const parsed = parseSegment(raw);
      if (!parsed || parsed.confidence >= minConfidence) continue;
      segments.push({
        tripId: trace.tripId,
        cityId: trace.cityId,
        coordinates: parsed.coordinates,
        confidence: parsed.confidence,
      });
    }
  }

  return segments;
}

function segmentCentroid(coords: [number, number][]): [number, number] {
  const point = coords[Math.floor(coords.length / 2)] ?? coords[0]!;
  return point;
}

/** Cluster low-confidence segments within clusterM and count distinct trips. */
export function clusterGeometryCorrections(
  segments: LowConfidenceSegment[],
  config: GeometryCorrectionsJobConfig,
): GeometryCorrectionInsert[] {
  const clusters: Array<{
    cityId: string;
    centroid: [number, number];
    tripIds: Set<string>;
    coordinates: [number, number][];
  }> = [];

  for (const segment of segments) {
    const centroid = segmentCentroid(segment.coordinates);
    let matchedCluster = clusters.find(
      (cluster) =>
        cluster.cityId === segment.cityId &&
        haversineM(cluster.centroid, centroid) <= config.clusterM,
    );

    if (!matchedCluster) {
      matchedCluster = {
        cityId: segment.cityId,
        centroid,
        tripIds: new Set<string>(),
        coordinates: segment.coordinates,
      };
      clusters.push(matchedCluster);
    }

    matchedCluster.tripIds.add(segment.tripId);
  }

  return clusters
    .filter((cluster) => cluster.tripIds.size >= config.minSupportingTraces)
    .map((cluster) => ({
      cityId: cluster.cityId,
      geometryGeoJson: {
        type: 'LineString' as const,
        coordinates:
          cluster.coordinates.length >= 2
            ? cluster.coordinates
            : [cluster.centroid, cluster.centroid],
      },
      supportingTraceCount: cluster.tripIds.size,
      tripIds: [...cluster.tripIds],
    }));
}

export async function runGeometryCorrectionsJob(
  db: GeometryCorrectionsDb,
): Promise<GeometryCorrectionsStats> {
  const config = await db.loadGeometryCorrectionsConfig();
  const jobRun = await db.beginJobRun('geometry-corrections', {
    min_supporting_traces: config.minSupportingTraces,
    cluster_m: config.clusterM,
    min_confidence: config.minConfidence,
  });

  const stats: GeometryCorrectionsStats = {
    traces_examined: 0,
    segments_extracted: 0,
    clusters_found: 0,
    corrections_inserted: 0,
  };

  try {
    const traces = await db.listMatchedTracesForGeometryCorrections();
    stats.traces_examined = traces.length;

    const segments = extractLowConfidenceSegments(traces, config.minConfidence);
    stats.segments_extracted = segments.length;

    const corrections = clusterGeometryCorrections(segments, config);
    stats.clusters_found = corrections.length;
    stats.corrections_inserted = await db.insertRoadGeometryCorrections(corrections);
    await db.finishJobRun(jobRun.id, 'succeeded', stats);
    return stats;
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    await db.finishJobRun(jobRun.id, 'failed', stats, message);
    throw err;
  }
}
