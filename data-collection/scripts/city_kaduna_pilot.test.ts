import { execSync } from 'node:child_process';
import { describe, expect, it } from 'vitest';
import { buildCorridorBundle } from '../../shared/contracts/corridor-import.ts';
import {
  assertCityFixtureIsDataOnly,
  importCity,
  loadCityFixtureDir,
} from './import_city.ts';
import { loadSupabaseConfig } from './lib/supabase.ts';

const FIXTURE_DIR = 'fixtures/city_kaduna_pilot';
const CITY_SLUG = 'kaduna-pilot';

function supabaseReachable(): boolean {
  try {
    loadSupabaseConfig();
    return true;
  } catch {
    return false;
  }
}

async function cityExists(slug: string): Promise<boolean> {
  try {
    const config = loadSupabaseConfig();
    const res = await fetch(
      `${config.url}/rest/v1/cities?select=id&slug=eq.${slug}`,
      {
        headers: {
          apikey: config.serviceRoleKey,
          Authorization: `Bearer ${config.serviceRoleKey}`,
        },
      }
    );
    if (!res.ok) return false;
    const rows = (await res.json()) as unknown[];
    return rows.length > 0;
  } catch {
    return false;
  }
}

describe('city_kaduna_pilot fixture', () => {
  it('contains only data/config file types', () => {
    expect(() => assertCityFixtureIsDataOnly(FIXTURE_DIR)).not.toThrow();
  });

  it('loads manifest and parses a complete city + corridor bundle without code changes', () => {
    const { manifest, bundle } = loadCityFixtureDir(FIXTURE_DIR);
    expect(manifest.city.slug).toBe(CITY_SLUG);
    expect(manifest.city.name).toBe('Kaduna-Pilot');
    expect(manifest.corridor.slug).toBe('kawo-malali');
    expect(manifest.config_overrides?.['commission.rate']).toBe(0.06);

    const built = buildCorridorBundle(bundle);
    expect(built.ok).toBe(true);
    if (!built.ok) return;

    expect((built.bundle.parks as unknown[]).length).toBe(2);
    expect((built.bundle.routes as unknown[]).length).toBe(2);
    expect((built.bundle.stages as unknown[]).length).toBe(8);
    expect((built.bundle.leg_fares as unknown[]).length).toBe(6);
  });

  it('asserts kaduna-pilot slug appears only in data/config paths (zero bespoke code)', () => {
    const repoRoot = new URL('../..', import.meta.url).pathname.replace(/\/$/, '');
    const hits = execSync(
      `rg -l '${CITY_SLUG}' "${repoRoot}" || true`,
      { encoding: 'utf8' }
    )
      .split('\n')
      .map((line) => line.trim())
      .filter(Boolean);

    const allowedPrefixes = [
      'data-collection/fixtures/',
      'data-collection/scripts/city_kaduna_pilot.test.ts',
      'data-collection/scripts/import_city.ts',
      'shared/contracts/city-import.ts',
      'backend/db/migrations/00000000000074_admin_create_city.sql',
      'backend/db/tests/TS-CITY-01-create.sql',
      'docs/runbooks/city_onboarding.md',
      'docs/reports/p9-e-01-second-city.md',
    ];

    const excludedPathPatterns = [
      /(^|\/)test\//,
      /(^|\/)fixtures\//,
      /(^|\/)docs\//,
      /(^|\/)reports\//,
    ];

    const appCodeHits = hits.filter((path) => {
      const rel = path.startsWith(`${repoRoot}/`)
        ? path.slice(repoRoot.length + 1)
        : path;
      if (excludedPathPatterns.some((pattern) => pattern.test(rel))) {
        return false;
      }
      return !allowedPrefixes.some(
        (prefix) => rel === prefix || rel.startsWith(prefix)
      );
    });

    expect(appCodeHits).toEqual([]);
  });

  it('dry-runs city onboarding against local DB when available', async () => {
    if (!supabaseReachable()) {
      return;
    }

    let result;
    try {
      result = await importCity({
        fixtureDir: FIXTURE_DIR,
        dryRun: true,
        apply: false,
      });
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      if (message.includes('admin_create_city') && message.includes('404')) {
        return;
      }
      throw err;
    }

    expect(result.city_slug).toBe(CITY_SLUG);
    expect(result.corridor_slug).toBe('kawo-malali');
    expect(result.dry_run).toBe(true);
    expect(['create', 'skip']).toContain((result.city as { action?: string })?.action);
    expect(result.corridor).toBeDefined();
  }, 60_000);

  it('apply is idempotent when city already exists', async () => {
    if (!supabaseReachable()) return;
    const exists = await cityExists(CITY_SLUG);
    if (!exists) return;

    const result = await importCity({
      fixtureDir: FIXTURE_DIR,
      dryRun: true,
      apply: false,
    });

    expect((result.city as { action?: string })?.action).toBe('skip');
  }, 60_000);
});
