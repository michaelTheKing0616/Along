import type { Point } from './types.ts';

const EARTH_RADIUS_M = 6_371_000;

/** Haversine distance in metres (doc 04 §1 fallback). */
export function distanceM(a: Point, b: Point): number {
  const toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(b.lat - a.lat);
  const dLng = toRad(b.lng - a.lng);
  const lat1 = toRad(a.lat);
  const lat2 = toRad(b.lat);
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLng / 2) ** 2;
  return 2 * EARTH_RADIUS_M * Math.asin(Math.min(1, Math.sqrt(h)));
}

/** Straight-line × 1.3 walking fallback when OSRM is unavailable (doc 01 §9). */
export function fallbackWalkDistanceM(a: Point, b: Point): number {
  return distanceM(a, b) * 1.3;
}

export function walkSeconds(distanceM: number, walkSpeedMps: number): number {
  return Math.round(distanceM / Math.max(walkSpeedMps, 0.1));
}

export function pointToCoord(p: Point): string {
  return `${p.lng},${p.lat}`;
}
