import { fallbackWalkDistanceM, walkSeconds } from './geo.ts';
import type { Point, WalkingStep } from './types.ts';

export type OsrmTableResult = {
  distances: number[][];
  durations: number[][];
  degraded: boolean;
};

export type OsrmRouteResult = {
  durationS: number;
  distanceM: number;
  degraded: boolean;
};

export type OsrmFootRouteResult = {
  distanceM: number;
  durationS: number;
  steps: WalkingStep[];
  polyline: Point[];
  degraded: boolean;
};

export interface OsrmClient {
  footTable(sources: Point[], destinations: Point[]): Promise<OsrmTableResult>;
  carRoute(from: Point, to: Point): Promise<OsrmRouteResult>;
  footRoute(from: Point, to: Point): Promise<OsrmFootRouteResult>;
}

type FetchFn = typeof fetch;

function straightLineTable(sources: Point[], destinations: Point[]): OsrmTableResult {
  const distances = sources.map((s) =>
    destinations.map((d) => Math.round(fallbackWalkDistanceM(s, d))),
  );
  const durations = distances.map((row) => row.map((m) => walkSeconds(m, 1.25)));
  return { distances, durations, degraded: true };
}

function straightLineFootRoute(from: Point, to: Point, walkSpeedMps: number): OsrmFootRouteResult {
  const distanceM = Math.round(fallbackWalkDistanceM(from, to));
  const durationS = walkSeconds(distanceM, walkSpeedMps);
  return {
    distanceM,
    durationS,
    steps: [{
      instruction: 'Walk to destination',
      distance_m: distanceM,
      bearing: 0,
      maneuver: 'depart',
      geometry: [from, to],
    }],
    polyline: [from, to],
    degraded: true,
  };
}

function parseFootRoute(body: {
  code?: string;
  routes?: Array<{
    distance?: number;
    duration?: number;
    geometry?: { coordinates?: number[][] };
    legs?: Array<{
      steps?: Array<{
        name?: string;
        distance?: number;
        duration?: number;
        maneuver?: { type?: string; modifier?: string; bearing_after?: number };
        geometry?: { coordinates?: number[][] };
      }>;
    }>;
  }>;
}, from: Point, to: Point, walkSpeedMps: number): OsrmFootRouteResult {
  const route = body.routes?.[0];
  if (body.code !== 'Ok' || !route) {
    return straightLineFootRoute(from, to, walkSpeedMps);
  }

  const polyline: Point[] = (route.geometry?.coordinates ?? []).map((c) => ({
    lng: c[0] ?? 0,
    lat: c[1] ?? 0,
  }));

  const steps: WalkingStep[] = [];
  for (const leg of route.legs ?? []) {
    for (const step of leg.steps ?? []) {
      const maneuver = step.maneuver?.type ?? 'continue';
      const modifier = step.maneuver?.modifier;
      const instruction = step.name
        ? `${maneuver}${modifier ? ` ${modifier}` : ''} onto ${step.name}`
        : `${maneuver}${modifier ? ` ${modifier}` : ''}`;
      steps.push({
        instruction,
        distance_m: Math.round(step.distance ?? 0),
        bearing: Math.round(step.maneuver?.bearing_after ?? 0),
        maneuver,
        geometry: (step.geometry?.coordinates ?? []).map((c) => ({
          lng: c[0] ?? 0,
          lat: c[1] ?? 0,
        })),
      });
    }
  }

  if (steps.length === 0) {
    return straightLineFootRoute(from, to, walkSpeedMps);
  }

  return {
    distanceM: Math.round(route.distance ?? 0),
    durationS: Math.round(route.duration ?? 0),
    steps,
    polyline: polyline.length > 0 ? polyline : [from, to],
    degraded: false,
  };
}

export function createOsrmClient(options?: {
  baseUrl?: string;
  timeoutMs?: number;
  walkSpeedMps?: number;
  fetchFn?: FetchFn;
}): OsrmClient {
  const baseUrl = (options?.baseUrl ?? Deno.env.get('OSRM_BASE_URL') ?? '').replace(/\/$/, '');
  const timeoutMs = options?.timeoutMs ??
    Number(Deno.env.get('OSRM_TIMEOUT_MS') ?? '800');
  const walkSpeedMps = options?.walkSpeedMps ?? 1.25;
  const fetchFn = options?.fetchFn ?? fetch;

  async function callOsrm(path: string): Promise<Response | null> {
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
    async footTable(sources, destinations) {
      if (sources.length === 0 || destinations.length === 0) {
        return { distances: [], durations: [], degraded: false };
      }
      const coords = [...sources, ...destinations]
        .map((p) => `${p.lng},${p.lat}`)
        .join(';');
      const sourceIdx = sources.map((_, i) => i).join(';');
      const destIdx = destinations.map((_, i) => i + sources.length).join(';');
      const path =
        `/table/v1/foot/${coords}?sources=${sourceIdx}&destinations=${destIdx}&annotations=distance,duration`;

      const res = await callOsrm(path);
      if (!res) return straightLineTable(sources, destinations);

      const body = await res.json() as {
        code?: string;
        distances?: number[][];
        durations?: number[][];
      };
      if (body.code !== 'Ok' || !body.distances || !body.durations) {
        return straightLineTable(sources, destinations);
      }
      return {
        distances: body.distances.map((row) => row.map((d) => Math.round(d ?? 0))),
        durations: body.durations.map((row) =>
          row.map((d) => Math.round(d ?? 0))
        ),
        degraded: false,
      };
    },

    async carRoute(from, to) {
      const path = `/route/v1/car/${from.lng},${from.lat};${to.lng},${to.lat}?overview=false`;
      const res = await callOsrm(path);
      if (!res) {
        const distanceM = Math.round(fallbackWalkDistanceM(from, to));
        return {
          durationS: walkSeconds(distanceM, 8),
          distanceM,
          degraded: true,
        };
      }
      const body = await res.json() as {
        code?: string;
        routes?: Array<{ duration?: number; distance?: number }>;
      };
      const route = body.routes?.[0];
      if (body.code !== 'Ok' || !route) {
        const distanceM = Math.round(fallbackWalkDistanceM(from, to));
        return {
          durationS: walkSeconds(distanceM, 8),
          distanceM,
          degraded: true,
        };
      }
      return {
        durationS: Math.round(route.duration ?? 0),
        distanceM: Math.round(route.distance ?? 0),
        degraded: false,
      };
    },

    async footRoute(from, to) {
      const path =
        `/route/v1/foot/${from.lng},${from.lat};${to.lng},${to.lat}?steps=true&geometries=geojson&overview=full`;
      const res = await callOsrm(path);
      if (!res) return straightLineFootRoute(from, to, walkSpeedMps);

      const body = await res.json() as Parameters<typeof parseFootRoute>[0];
      return parseFootRoute(body, from, to, walkSpeedMps);
    },
  };
}
