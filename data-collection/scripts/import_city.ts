#!/usr/bin/env node
/**
 * City onboarding CLI (doc 13, P9-E-01).
 * Reads a city fixture (manifest.json + corridor CSVs) and runs:
 * admin_create_city → admin_import_dry_run → admin_import_apply
 */

import { readFileSync, readdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  buildCorridorBundle,
  CORRIDOR_IMPORT_RPC,
  type CorridorManifest,
} from '../../shared/contracts/corridor-import.ts';
import {
  CITY_IMPORT_RPC,
  cityConfigOverridesJson,
  parseCityFixtureManifest,
  type CityFixtureManifest,
} from '../../shared/contracts/city-import.ts';
import {
  loadSupabaseConfig,
  supabaseGet,
  supabaseRpc,
  type CityRow,
} from './lib/supabase.ts';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');

export interface ImportCityOptions {
  fixtureDir: string;
  dryRun?: boolean;
  apply?: boolean;
  config?: ReturnType<typeof loadSupabaseConfig>;
}

export function loadCityFixtureDir(fixtureDir: string): {
  manifest: CityFixtureManifest;
  bundle: CorridorManifest;
} {
  const resolved = fixtureDir.startsWith('/') ? fixtureDir : join(ROOT, fixtureDir);
  const raw = JSON.parse(readFileSync(join(resolved, 'manifest.json'), 'utf8'));
  const manifest = parseCityFixtureManifest(raw);

  const readCsv = (name: string) => readFileSync(join(resolved, name), 'utf8');

  const bundle: CorridorManifest = {
    corridor: manifest.corridor,
    parks: readCsv('parks.csv'),
    routes: readCsv('routes.csv'),
    stages: readCsv('stages.csv'),
    leg_fares: readCsv('leg_fares.csv'),
    through_fares: readCsv('through_fares.csv'),
  };

  return { manifest, bundle };
}

export function assertCityFixtureIsDataOnly(fixtureDir: string): void {
  const resolved = fixtureDir.startsWith('/') ? fixtureDir : join(ROOT, fixtureDir);
  const allowed = new Set(['.csv', '.json', '.md']);
  for (const entry of readdirSync(resolved)) {
    const ext = entry.includes('.') ? entry.slice(entry.lastIndexOf('.')) : '';
    if (!allowed.has(ext)) {
      throw new Error(`Fixture contains non-data file: ${entry}`);
    }
  }
}

export async function importCity(options: ImportCityOptions) {
  assertCityFixtureIsDataOnly(options.fixtureDir);
  const { manifest, bundle } = loadCityFixtureDir(options.fixtureDir);
  const built = buildCorridorBundle(bundle);
  if (!built.ok) {
    throw new Error(built.errors.join('; '));
  }

  const config = options.config ?? loadSupabaseConfig();
  const dryRun = options.dryRun ?? !options.apply;

  const configOverrides = cityConfigOverridesJson(manifest.config_overrides);
  const cityResult = await supabaseRpc<Record<string, unknown>>(
    config,
    CITY_IMPORT_RPC.create,
    {
      p_name: manifest.city.name,
      p_slug: manifest.city.slug,
      p_country_code: manifest.city.country_code,
      p_centroid_lat: manifest.city.centroid.lat,
      p_centroid_lng: manifest.city.centroid.lng,
      p_state_region: manifest.city.state_region ?? null,
      p_status: manifest.city.status ?? 'alpha',
      p_config_overrides: configOverrides,
      p_dry_run: dryRun,
    }
  );

  const cityId =
    typeof cityResult?.city_id === 'string'
      ? cityResult.city_id
      : dryRun
        ? undefined
        : undefined;

  let resolvedCityId = cityId;
  if (!resolvedCityId) {
    const cities = await supabaseGet<CityRow[]>(config, 'cities', {
      select: 'id,slug,name',
      slug: `eq.${manifest.city.slug}`,
    });
    resolvedCityId = cities[0]?.id;
  }

  if (!resolvedCityId && dryRun && cityResult?.action === 'create') {
    return {
      city_slug: manifest.city.slug,
      corridor_slug: manifest.corridor.slug,
      dry_run: true,
      city: cityResult,
      corridor: { dry_run: true, creates: 0, diff: [] as Array<Record<string, unknown>> },
    };
  }

  if (!resolvedCityId) {
    throw new Error(`City not available for slug: ${manifest.city.slug}`);
  }

  const payload = JSON.stringify(built.bundle);
  const dryRunResult = await supabaseRpc<{ kind: string; diff: Array<Record<string, unknown>> }>(
    config,
    CORRIDOR_IMPORT_RPC.dryRun,
    { p_city_id: resolvedCityId, p_csv: payload }
  );

  const diff = dryRunResult?.diff ?? [];
  const creates = diff.filter((row) => row.action === 'create');

  if (dryRun || !options.apply) {
    return {
      city_id: resolvedCityId,
      city_slug: manifest.city.slug,
      corridor_slug: manifest.corridor.slug,
      dry_run: true,
      city: cityResult,
      corridor: { creates: creates.length, diff },
    };
  }

  const applyResult = await supabaseRpc<{ created: number; skipped: number }>(
    config,
    CORRIDOR_IMPORT_RPC.apply,
    { p_city_id: resolvedCityId, p_diff: diff }
  );

  return {
    city_id: resolvedCityId,
    city_slug: manifest.city.slug,
    corridor_slug: manifest.corridor.slug,
    dry_run: false,
    city: cityResult,
    corridor: {
      created: applyResult?.created ?? 0,
      skipped: applyResult?.skipped ?? 0,
      diff,
    },
  };
}

async function main(): Promise<void> {
  const args = process.argv.slice(2);
  const fixtureIdx = args.indexOf('--fixture');
  const dryRun = args.includes('--dry-run');
  const apply = args.includes('--apply');

  if (fixtureIdx === -1 || args[fixtureIdx + 1] === undefined) {
    console.error('Usage: import_city.ts --fixture <dir> [--dry-run] [--apply]');
    process.exit(1);
  }

  if (!dryRun && !apply) {
    console.error('Provide --dry-run and/or --apply');
    process.exit(1);
  }

  const result = await importCity({
    fixtureDir: args[fixtureIdx + 1]!,
    dryRun: dryRun || !apply,
    apply,
  });

  console.log(JSON.stringify(result, null, 2));
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main().catch((err) => {
    console.error(err);
    process.exit(1);
  });
}
