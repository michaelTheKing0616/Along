import type { GeoJsonLineString, OsrmMatchResult, TraceSample } from './types.js';

type FetchFn = typeof fetch;

type OsrmMatchResponse = {
  code?: string;
  matchings?: Array<{
    confidence?: number;
    geometry?: GeoJsonLineString;
  }>;
};

export type OsrmMatchClient = {
  carMatch(samples: TraceSample[], defaultRadiusM: number): Promise<OsrmMatchResult>;
};

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
        `/match/v1/car/${coords}?geometries=geojson&overview=full&radiuses=${radiuses}&timestamps=${timestamps}&gaps=ignore`;

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

      return {
        confidence: matching.confidence ?? 0,
        geometry: matching.geometry,
        osmWayIds: [],
        matchMeta: {
          code: body.code,
          matching_count: body.matchings?.length ?? 0,
        },
        degraded: false,
      };
    },
  };
}
