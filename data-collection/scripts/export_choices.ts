#!/usr/bin/env node
/**
 * Export ODK choice lists from DB (doc 13 §2 — corridors, modes, parks).
 * Writes CSV under forms/choices/ for build_forms.ts to embed in XLSForms.
 */

import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  loadSupabaseConfig,
  supabaseGet,
  type CorridorRow,
  type ModeRow,
  type ParkRow,
} from './lib/supabase.ts';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const OUT = join(ROOT, 'forms', 'choices');

function writeCsv(filename: string, headers: string[], rows: string[][]): void {
  mkdirSync(OUT, { recursive: true });
  const body = [headers.join(','), ...rows.map((r) => r.map(csvEscape).join(','))].join('\n');
  writeFileSync(join(OUT, filename), `${body}\n`);
}

function csvEscape(value: string): string {
  if (value.includes(',') || value.includes('"') || value.includes('\n')) {
    return `"${value.replace(/"/g, '""')}"`;
  }
  return value;
}

async function main(): Promise<void> {
  const config = loadSupabaseConfig();

  const modes = await supabaseGet<ModeRow[]>(config, 'mode_config', {
    select: 'code,label',
    order: 'sort_order.asc',
  });

  const corridors = await supabaseGet<CorridorRow[]>(config, 'corridors', {
    select: 'id,name,slug,city_id',
    order: 'name.asc',
  });

  const parks = await supabaseGet<ParkRow[]>(config, 'parks', {
    select: 'id,name,city_id',
    order: 'name.asc',
  });

  writeCsv(
    'modes.csv',
    ['list_name', 'name', 'label'],
    modes.map((m) => ['modes', m.code, m.label])
  );

  writeCsv(
    'corridors.csv',
    ['list_name', 'name', 'label'],
    corridors.map((c) => ['corridors', c.id, c.name])
  );

  writeCsv(
    'parks.csv',
    ['list_name', 'name', 'label'],
    parks.map((p) => ['parks', p.id, p.name])
  );

  console.log(`Exported ${modes.length} modes, ${corridors.length} corridors, ${parks.length} parks → forms/choices/`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
