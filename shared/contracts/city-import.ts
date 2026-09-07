/**
 * City onboarding fixture contract (doc 13, P9-E-01).
 * Consumed by data-collection import_city CLI and A-08 city deploy path.
 */

import type { CorridorManifest } from './corridor-import.ts';

export type CityManifestCity = {
  name: string;
  slug: string;
  country_code: string;
  state_region?: string;
  status?: 'pre_seed' | 'alpha' | 'beta' | 'live' | 'paused';
  centroid: { lat: number; lng: number };
};

export type CityFixtureManifest = {
  city: CityManifestCity;
  corridor: CorridorManifest['corridor'];
  config_overrides?: Record<string, string | number | boolean>;
  description?: string;
};

export const CITY_IMPORT_RPC = {
  create: 'admin_create_city',
} as const;

export const CITY_DATA_ONLY_EXTENSIONS = ['.csv', '.json', '.md'] as const;

export function parseCityFixtureManifest(raw: unknown): CityFixtureManifest {
  if (!raw || typeof raw !== 'object') {
    throw new Error('manifest.json must be an object');
  }
  const m = raw as Record<string, unknown>;
  const city = m.city as CityManifestCity | undefined;
  const corridor = m.corridor as CorridorManifest['corridor'] | undefined;

  if (!city?.name?.trim() || !city?.slug?.trim()) {
    throw new Error('city.name and city.slug are required');
  }
  if (!city.country_code?.trim()) {
    throw new Error('city.country_code is required');
  }
  if (
    city.centroid == null
    || !Number.isFinite(city.centroid.lat)
    || !Number.isFinite(city.centroid.lng)
  ) {
    throw new Error('city.centroid.lat and city.centroid.lng are required numbers');
  }
  if (!corridor?.name?.trim() || !corridor?.slug?.trim()) {
    throw new Error('corridor.name and corridor.slug are required');
  }

  return {
    city,
    corridor,
    config_overrides: (m.config_overrides as CityFixtureManifest['config_overrides']) ?? {},
    description: typeof m.description === 'string' ? m.description : undefined,
  };
}

export function cityConfigOverridesJson(
  overrides: CityFixtureManifest['config_overrides']
): Record<string, unknown> {
  const out: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(overrides ?? {})) {
    out[key] = value;
  }
  return out;
}

/** Paths that may change when adding a city — application code must stay untouched. */
export const CITY_DATA_ONLY_PREFIXES = [
  'data-collection/fixtures/',
  'backend/db/seed/',
  'docs/runbooks/',
  'docs/reports/',
] as const;
