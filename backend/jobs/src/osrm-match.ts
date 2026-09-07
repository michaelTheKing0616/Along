import type { GeoJsonLineString, OsrmMatchResult, TraceSample } from './types.js';

type FetchFn = typeof fetch;

type OsrmMatchStep = {
  distance?: number;
  duration?: number;
};

type OsrmMatchResponse = {
  code?: string;
  matchings?: Array<{
    confidence?: number;
    geometry?: GeoJsonLineString;
    distance?: number;
    duration?: number;
    legs?: Array<{ steps?: OsrmMatchStep[] }>;
  }>;
};

export type OsrmMatchClient = {
  carMatch(samples: TraceSample[], defaultRadiusM: number): Promise<OsrmMatchResult>;
};

function interpolateTimestamp(
  samples: TraceSample[],
  fraction: number,
): Date {
  if (samples.length === 0) return new Date();
  if (samples.length === 1) return samples[0]!.ts;

  const start = samples[0]!.ts.getTime();
  const end = samples[samples.length - 1]!.ts.getTime();
  const clamped = Math.min(1, Math.max(0, fraction));
  return new Date(start + (end - start) * clamped);
}

function buildSegmentObservations(
  samples: TraceSample[],
  matching: NonNullable<OsrmMatchResponse['matchings']>[number],
  osmWayIds: number[],
): Array<{ segment_key: string; speed_mps: number; observed_at: string }> {
  const steps = matching.legs?.flatMap((leg) => leg.steps ?? []) ?? [];
  if (steps.length === 0) return [];

  const observations: Array<{ segment_key: string; speed_mps: number; observed_at: string }> = [];
  let stepIndex = 0;

  for (const step of steps) {
    const distanceM = Number(step.distance ?? 0);
    const durationS = Number(step.duration ?? 0);
    if (distanceM <= 0 || durationS <= 0) {
      stepIndex += 1;
      continue;
    }

    const wayId = osmWayIds[stepIndex] ?? osmWayIds[stepIndex % Math.max(osmWayIds.length, 1)];
    if (wayId === undefined) {
      stepIndex += 1;
      continue;
    }

    const direction = stepIndex % 2 === 0 ? 'forward' : 'reverse';
    const observedAt = interpolateTimestamp(samples, stepIndex / Math.max(steps.length - 1, 1));
    observations.push({
      segment_key: `${wayId}:${direction}`,
      speed_mps: Math.round((distanceM / durationS) * 100) / 100,
      observed_at: observedAt.toISOString(),
    });
    stepIndex += 1;
  }

  return observations;
}

export function createOsrmMatchClient(options?: {
  baseUrl?: string;
  timeoutMs?: number;
  fetchFn?: FetchFn;
}): OsrmMatchClient {
  const baseUrl = (
    options?.baseUrl ??
    process.env.OSRM_BASE_URL ??
    process.env.OSRM_URL ??
    ''
  ).replace(/\/$/, '');
  const timeoutMs = options?.timeoutMs ??
    Number(process.env.OSRM_TIMEOUT_MS ?? '8000');
  const fetchFn = options?.fetchFn ?? fetch;

  async function callMatch(path: string): Promise<Response | null> {
    if (!baseUrl) return null;
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs);
    try {
      const res = await fetchFn(`${baseUrl}${path}`, { signal: controller.signal });
      if (!res.ok) return null;
      return res;
    } catch {
      return null;
    } finally {
      clearTimeout(timer);
    }
  }

  return {
    async carMatch(samples, defaultRadiusM) {
      if (samples.length === 0) {
        return {
          confidence: 0,
          geometry: { type: 'LineString', coordinates: [] },
          osmWayIds: [],
          matchMeta: { error: 'empty_trace' },
          degraded: true,
        };
      }

      const coords = samples.map((s) => `${s.lng},${s.lat}`).join(';');
      const radiuses = samples
        .map((s) => Math.max(1, Math.round(s.accuracyM ?? defaultRadiusM)))
        .join(';');
      const timestamps = samples
        .map((s) => Math.floor(s.ts.getTime() / 1000))
        .join(';');
      const path =
        `/match/v1/car/${coords}?geometries=geojson&overview=full&steps=true&radiuses=${radiuses}&timestamps=${timestamps}&gaps=ignore`;

      const res = await callMatch(path);
      if (!res) {
        return {
          confidence: 0,
          geometry: {
            type: 'LineString',
            coordinates: samples.map((s) => [s.lng, s.lat]),
          },
          osmWayIds: [],
          matchMeta: { error: 'osrm_unavailable' },
          degraded: true,
        };
      }

      const body = await res.json() as OsrmMatchResponse;
      const matching = body.matchings?.[0];
      if (body.code !== 'Ok' || !matching?.geometry) {
        return {
          confidence: 0,
          geometry: {
            type: 'LineString',
            coordinates: samples.map((s) => [s.lng, s.lat]),
          },
          osmWayIds: [],
          matchMeta: { code: body.code ?? 'NoMatch' },
          degraded: true,
        };
      }

      const osmWayIds: number[] = [];
      const segmentObservations = buildSegmentObservations(samples, matching, osmWayIds);

      return {
        confidence: matching.confidence ?? 0,
        geometry: matching.geometry,
        osmWayIds,
        matchMeta: {
          code: body.code,
          matching_count: body.matchings?.length ?? 0,
          distance_m: matching.distance ?? null,
          duration_s: matching.duration ?? null,
          started_at: samples[0]?.ts.toISOString() ?? null,
          segment_observations: segmentObservations,
        },
        degraded: false,
      };
    },
  };
}
