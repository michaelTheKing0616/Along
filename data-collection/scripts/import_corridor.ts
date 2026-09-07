#!/usr/bin/env node
/**
 * Corridor backbone import CLI (doc 13 §4, P7-E-01).
 * Reads a fixture directory (manifest.json + CSV sections) and runs
 * admin_import_dry_run → admin_import_apply via service role.
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
  loadSupabaseConfig,
  supabaseGet,
  supabaseRpc,
  type CityRow,
} from './lib/supabase.ts';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');

export interface FixtureManifest {
  corridor: { name: string; slug: string };
  target_city_slug: string;
  description?: string;
}

export interface ImportCorridorOptions {
  fixtureDir: string;
  dryRun?: boolean;
  apply?: boolean;
  config?: ReturnType<typeof loadSupabaseConfig>;
}

export function loadFixtureDir(fixtureDir: string): {
  manifest: FixtureManifest;
  bundle: CorridorManifest;
} {
  const resolved = fixtureDir.startsWith('/') ? fixtureDir : join(ROOT, fixtureDir);
  const manifest = JSON.parse(
    readFileSync(join(resolved, 'manifest.json'), 'utf8')
  ) as FixtureManifest;

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

export function assertFixtureIsDataOnly(fixtureDir: string): void {
  const resolved = fixtureDir.startsWith('/') ? fixtureDir : join(ROOT, fixtureDir);
  const allowed = new Set(['.csv', '.json', '.md', '.sql']);
  for (const entry of readdirSync(resolved)) {
    const ext = entry.includes('.') ? entry.slice(entry.lastIndexOf('.')) : '';
    if (!allowed.has(ext)) {
      throw new Error(`Fixture contains non-data file: ${entry}`);
    }
  }
}

export async function importCorridor(options: ImportCorridorOptions) {
  assertFixtureIsDataOnly(options.fixtureDir);
  const { manifest, bundle } = loadFixtureDir(options.fixtureDir);
  const built = buildCorridorBundle(bundle);
  if (!built.ok) {
    throw new Error(built.errors.join('; '));
  }

  const config = options.config ?? loadSupabaseConfig();
  const cities = await supabaseGet<CityRow[]>(config, 'cities', {
    select: 'id,slug,name',
    slug: `eq.${manifest.target_city_slug}`,
  });
  const city = cities[0];
  if (!city) {
    throw new Error(`City not found for slug: ${manifest.target_city_slug}`);
  }

  const payload = JSON.stringify(built.bundle);
  const dryRunResult = await supabaseRpc<{ kind: string; diff: Array<Record<string, unknown>> }>(
    config,
    CORRIDOR_IMPORT_RPC.dryRun,
    { p_city_id: city.id, p_csv: payload }
  );

  const diff = dryRunResult?.diff ?? [];
  const creates = diff.filter((row) => row.action === 'create');

  if (options.dryRun || !options.apply) {
    return {
      city_id: city.id,
      city_slug: city.slug,
      corridor_slug: manifest.corridor.slug,
      dry_run: true,
      creates: creates.length,
      diff,
    };
  }

  const applyResult = await supabaseRpc<{ created: number; skipped: number }>(
    config,
    CORRIDOR_IMPORT_RPC.apply,
    { p_city_id: city.id, p_diff: diff }
  );

  return {
    city_id: city.id,
    city_slug: city.slug,
    corridor_slug: manifest.corridor.slug,
    dry_run: false,
    created: applyResult?.created ?? 0,
    skipped: applyResult?.skipped ?? 0,
    diff,
  };
}

async function main(): Promise<void> {
  const args = process.argv.slice(2);
  const fixtureIdx = args.indexOf('--fixture');
  const dryRun = args.includes('--dry-run');
  const apply = args.includes('--apply');

  if (fixtureIdx === -1 || args[fixtureIdx + 1] === undefined) {
    console.error('Usage: import_corridor.ts --fixture <dir> [--dry-run] [--apply]');
    process.exit(1);
  }

  if (!dryRun && !apply) {
    console.error('Provide --dry-run and/or --apply');
    process.exit(1);
  }

  const result = await importCorridor({
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
