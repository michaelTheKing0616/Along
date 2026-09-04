/**
 * Entity key helpers — mirrors shared/contracts/field-ingestion.ts (doc 13 §3 step 2).
 */

export function slugifyName(name: string): string {
  return name
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

export function entityKeyForPark(citySlug: string, parkName: string): string {
  return `park:${citySlug}:${slugifyName(parkName)}`;
}

export function entityKeyForRoute(
  citySlug: string,
  originSlug: string,
  destinationSlug: string,
  modeCode: string
): string {
  return `route:${citySlug}:${originSlug}-${destinationSlug}:${modeCode}`;
}

export function entityKeyForStage(routeEntityKey: string, sequence: number): string {
  return `${routeEntityKey}:stage:${sequence}`;
}

export function entityKeyForLegFare(
  routeEntityKey: string,
  fromSequence: number,
  toSequence: number
): string {
  return `${routeEntityKey}:fare:${fromSequence}-${toSequence}`;
}

export function entityKeyForThroughFare(
  routeEntityKey: string,
  fromSequence: number,
  toSequence: number
): string {
  return `${routeEntityKey}:through_fare:${fromSequence}-${toSequence}`;
}

/** Parse ODK geopoint "lat lng alt accuracy" → { lat, lng }. */
export function parseGeopoint(raw: string): { lat: number; lng: number } {
  const parts = raw.trim().split(/\s+/);
  if (parts.length < 2) {
    throw new Error(`Invalid geopoint: ${raw}`);
  }
  const lat = Number(parts[0]);
  const lng = Number(parts[1]);
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
    throw new Error(`Invalid geopoint coordinates: ${raw}`);
  }
  return { lat, lng };
}

/** Resolve park slug from ODK select value (uuid or "slug|label" or plain name). */
export function resolveParkSlug(value: string, label?: string): string {
  if (value.includes('|')) {
    return value.split('|')[0]!;
  }
  if (/^[0-9a-f-]{36}$/i.test(value) && label) {
    return slugifyName(label);
  }
  return slugifyName(value);
}
