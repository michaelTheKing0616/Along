import { distanceM } from './geo.ts';
import type { PlaceResult, Point } from './types.ts';

type FetchFn = typeof fetch;

export type PhotonClient = {
  search(
    q: string,
    near: Point,
    limit: number,
  ): Promise<{ results: PlaceResult[]; degraded: boolean }>;
};

function areaFromProperties(props: Record<string, unknown>): string {
  const city = props.city ?? props.locality ?? props.district ?? props.state;
  return typeof city === 'string' ? city : '';
}

export function createPhotonClient(options: {
  baseUrl?: string;
  timeoutMs: number;
  fetchFn?: FetchFn;
}): PhotonClient {
  const baseUrl = (options.baseUrl ?? Deno.env.get('PHOTON_BASE_URL') ?? '').replace(/\/$/, '');
  const timeoutMs = options.timeoutMs;
  const fetchFn = options.fetchFn ?? fetch;

  return {
    async search(q, near, limit) {
      if (!baseUrl || limit <= 0) {
        return { results: [], degraded: true };
      }

      const params = new URLSearchParams({
        q,
        lat: String(near.lat),
        lon: String(near.lng),
        limit: String(limit),
      });

      const controller = new AbortController();
      const timer = setTimeout(() => controller.abort(), timeoutMs);
      try {
        const res = await fetchFn(`${baseUrl}/api?${params}`, {
          signal: controller.signal,
        });
        if (!res.ok) return { results: [], degraded: true };

        const body = await res.json() as {
          features?: Array<{
            geometry?: { coordinates?: number[] };
            properties?: Record<string, unknown>;
          }>;
        };

        const results: PlaceResult[] = (body.features ?? []).slice(0, limit).map((f) => {
          const coords = f.geometry?.coordinates ?? [near.lng, near.lat];
          const location = { lng: coords[0] ?? near.lng, lat: coords[1] ?? near.lat };
          const props = f.properties ?? {};
          const name = typeof props.name === 'string' ? props.name : q;
          return {
            kind: 'place' as const,
            name,
            area: areaFromProperties(props),
            location,
            distance_m: Math.round(distanceM(near, location)),
          };
        });

        return { results, degraded: false };
      } catch {
        return { results: [], degraded: true };
      } finally {
        clearTimeout(timer);
      }
    },
  };
}
