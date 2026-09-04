#!/usr/bin/env node
/**
 * Field submission ingestion (doc 13 §3).
 * Pulls ODK/Kobo submissions (API or local fixture) → field_submissions → reconcile_field_submission.
 * Uses Supabase service-role (orchestrator decision).
 */

import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { mapOdkSubmission, type OdkSubmission } from './lib/odk_map.ts';
import {
  loadSupabaseConfig,
  supabaseGet,
  supabaseInsert,
  supabaseRpc,
  type CityRow,
} from './lib/supabase.ts';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');

export interface IngestResult {
  submission_uid: string;
  entity_key: string;
  entity_type: string;
  submission_id: string;
  reconciliation_id: string;
}

export interface IngestOptions {
  config?: ReturnType<typeof loadSupabaseConfig>;
  dryRun?: boolean;
}

async function loadCityMap(config: ReturnType<typeof loadSupabaseConfig>): Promise<Map<string, string>> {
  const cities = await supabaseGet<CityRow[]>(config, 'cities', { select: 'id,slug,name' });
  return new Map(cities.map((c) => [c.id, c.slug]));
}

export async function ingestOdkSubmission(
  raw: OdkSubmission,
  cityId: string,
  options: IngestOptions = {}
): Promise<IngestResult[]> {
  const config = options.config ?? loadSupabaseConfig();
  const cityMap = await loadCityMap(config);
  const citySlug = cityMap.get(cityId);
  if (!citySlug) {
    throw new Error(`city_id not found in cities table: ${cityId}`);
  }

  const mapped = mapOdkSubmission(raw, { cityId, citySlug });
  const results: IngestResult[] = [];

  for (const row of mapped) {
    if (options.dryRun) {
      results.push({
        submission_uid: row.submission_uid,
        entity_key: row.entity_key,
        entity_type: row.entity_type,
        submission_id: '(dry-run)',
        reconciliation_id: '(dry-run)',
      });
      continue;
    }

    const inserted = await supabaseInsert(config, 'field_submissions', {
      city_id: row.city_id,
      corridor_id: row.corridor_id,
      scout_profile_id: row.scout_profile_id,
      form_id: row.form_id,
      form_version: row.form_version,
      submission_uid: row.submission_uid,
      payload: row.payload,
      gpx_storage_path: row.gpx_storage_path ?? null,
      entity_type: row.entity_type,
      entity_key: row.entity_key,
      submitted_at: row.submitted_at,
      status: 'received',
    });

    const reconciliationId = await supabaseRpc<string>(config, 'reconcile_field_submission', {
      p_submission_id: inserted.id,
    });

    results.push({
      submission_uid: row.submission_uid,
      entity_key: row.entity_key,
      entity_type: row.entity_type,
      submission_id: inserted.id,
      reconciliation_id: reconciliationId,
    });
  }

  return results;
}

async function fetchKoboSubmissions(
  config: ReturnType<typeof loadSupabaseConfig>,
  assetUid: string,
  token: string
): Promise<OdkSubmission[]> {
  const base = process.env.KOBO_API_URL ?? 'https://kf.kobotoolbox.org';
  const res = await fetch(`${base}/api/v2/assets/${assetUid}/data/?format=json`, {
    headers: { Authorization: `Token ${token}` },
  });
  if (!res.ok) {
    throw new Error(`Kobo fetch failed (${res.status}): ${await res.text()}`);
  }
  const data = (await res.json()) as { results: OdkSubmission[] };
  return data.results;
}

async function main(): Promise<void> {
  const args = process.argv.slice(2);
  const fixtureIdx = args.indexOf('--fixture');
  const cityIdx = args.indexOf('--city-id');
  const koboIdx = args.indexOf('--kobo-asset');
  const dryRun = args.includes('--dry-run');

  if (cityIdx === -1 || args[cityIdx + 1] === undefined) {
    console.error('Usage: ingest.ts --city-id <uuid> [--fixture path.json] [--kobo-asset uid] [--dry-run]');
    process.exit(1);
  }

  const cityId = args[cityIdx + 1]!;
  const config = loadSupabaseConfig();
  let submissions: OdkSubmission[] = [];

  if (fixtureIdx !== -1) {
    const path = args[fixtureIdx + 1]!;
    const resolved = path.startsWith('/') ? path : join(ROOT, path);
    const parsed = JSON.parse(readFileSync(resolved, 'utf8')) as OdkSubmission | OdkSubmission[];
    submissions = Array.isArray(parsed) ? parsed : [parsed];
  } else if (koboIdx !== -1) {
    const assetUid = args[koboIdx + 1]!;
    const token = process.env.KOBO_API_TOKEN;
    if (!token) {
      throw new Error('KOBO_API_TOKEN required for --kobo-asset');
    }
    submissions = await fetchKoboSubmissions(config, assetUid, token);
  } else {
    console.error('Provide --fixture or --kobo-asset');
    process.exit(1);
  }

  const allResults: IngestResult[] = [];
  for (const sub of submissions) {
    const results = await ingestOdkSubmission(sub, cityId, { config, dryRun });
    allResults.push(...results);
  }

  console.log(JSON.stringify(allResults, null, 2));
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main().catch((err) => {
    console.error(err);
    process.exit(1);
  });
}
