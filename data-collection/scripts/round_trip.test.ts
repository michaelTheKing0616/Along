import { execSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { ingestOdkSubmission } from './ingest.ts';
import { fetchReconciliation, loadSupabaseConfig } from './lib/supabase.ts';
import type { OdkSubmission } from './lib/odk_map.ts';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const DB_URL = process.env.DATABASE_URL ?? 'postgresql://postgres:postgres@127.0.0.1:54322/postgres';

const CITY_ID = 'f0000000-0000-4000-8000-000000000002';
const SCOUT_A = 'f0000000-0000-4000-8000-000000000010';
const SCOUT_B = 'f0000000-0000-4000-8000-000000000011';
const CORRIDOR_ID = 'f0000000-0000-4000-8000-000000000100';

function psqlFile(filename: string): void {
  const path = join(ROOT, 'fixtures', filename);
  execSync(`psql "${DB_URL}" -f "${path}"`, { stdio: 'pipe' });
}

function psqlOne(sql: string): string {
  return execSync(`psql "${DB_URL}" -t -A -c "${sql.replace(/"/g, '\\"')}"`, { encoding: 'utf8' }).trim();
}

function applyMigration10(): void {
  const migration = join(ROOT, '../backend/db/migrations/00000000000010_field_ingest_service_role.sql');
  execSync(`psql "${DB_URL}" -f "${migration}"`, { stdio: 'pipe' });
}

function seedRoundTripFixtures(): void {
  psqlFile('round_trip_setup.sql');
}

function cleanupRoundTripData(): void {
  psqlFile('round_trip_cleanup.sql');
}

function loadFixture(name: string): OdkSubmission[] {
  return JSON.parse(readFileSync(join(ROOT, 'fixtures', name), 'utf8')) as OdkSubmission[];
}

describe('field ingestion round-trip (P0-E-03)', () => {
  const config = loadSupabaseConfig();

  beforeAll(() => {
    applyMigration10();
    seedRoundTripFixtures();
    cleanupRoundTripData();
  });

  afterAll(() => {
    cleanupRoundTripData();
  });

  it('park: two scouts → matched reconciliation with location variance within tolerance', async () => {
    const fixtures = loadFixture('park_matched_pair.json');
    for (const sub of fixtures) {
      await ingestOdkSubmission(sub, CITY_ID, { config });
    }

    const rec = await fetchReconciliation(config, 'park:round-trip-city:round-trip-park');
    expect(rec).not.toBeNull();
    expect(rec!.status).toBe('matched');

    const variance = rec!.variance as Record<string, unknown>;
    expect(variance.within_tolerance).toBe(true);
    expect(typeof variance.location_m).toBe('number');
    expect(variance.location_m as number).toBeGreaterThan(0);
    expect(variance.location_m as number).toBeLessThan(50);
    expect(variance.name_similarity).toBe(1);

    const count = Number(
      psqlOne("select count(*) from field_submissions where entity_key = 'park:round-trip-city:round-trip-park'")
    );
    expect(count).toBe(2);
  });

  it('route: two scouts → matched route + stage_count variance', async () => {
    const fixtures = loadFixture('route_matched_pair.json');
    for (const sub of fixtures) {
      await ingestOdkSubmission(sub, CITY_ID, { config });
    }

    const routeKey = 'route:round-trip-city:nyanya-park-berger-junction:car';
    const rec = await fetchReconciliation(config, routeKey);
    expect(rec).not.toBeNull();
    expect(rec!.status).toBe('matched');

    const variance = rec!.variance as Record<string, unknown>;
    expect(variance.within_tolerance).toBe(true);
    expect(variance.stage_count_diff).toBe(0);

    const legRec = await fetchReconciliation(config, `${routeKey}:fare:1-3`);
    expect(legRec).not.toBeNull();
    expect(legRec!.status).toBe('matched');
    const legVariance = legRec!.variance as Record<string, unknown>;
    expect(legVariance.within_tolerance).toBe(true);
    expect(typeof legVariance.fare_pct).toBe('number');
    expect(legVariance.fare_pct as number).toBeLessThan(0.15);
  });
});
