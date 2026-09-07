'use server';

import type { Json } from '@along/contracts/db.types';
import { revalidatePath } from 'next/cache';
import { createClient } from '@/lib/supabase/server';
import type { ParkImportDiffRow } from '@/lib/deploy/csv-parks';
import {
  corridorImportPayload,
  type CorridorImportDiffRow,
  validateCorridorManifest,
} from '@/lib/deploy/corridor-bundle';
import type { CorridorManifest } from '@along/contracts';

export type DeployActionResult =
  | { ok: true; created: number; skipped: number }
  | { ok: false; error: string };

export type CorridorDryRunResult =
  | { ok: true; diff: CorridorImportDiffRow[]; summary: Record<string, number> }
  | { ok: false; error: string };

function summarizeDiff(diff: CorridorImportDiffRow[]) {
  return diff
    .filter((row) => row.action === 'create')
    .reduce<Record<string, number>>((acc, row) => {
      acc[row.entity] = (acc[row.entity] ?? 0) + 1;
      return acc;
    }, {});
}

export async function dryRunCorridorImport(
  cityId: string,
  manifest: CorridorManifest
): Promise<CorridorDryRunResult> {
  const validated = validateCorridorManifest(manifest);
  if (!validated.ok) {
    return { ok: false, error: validated.errors.join('; ') };
  }

  let payload: string;
  try {
    payload = corridorImportPayload(manifest);
  } catch (err) {
    return { ok: false, error: err instanceof Error ? err.message : 'Invalid corridor bundle' };
  }

  const supabase = await createClient();
  const { data, error } = await supabase.rpc('admin_import_dry_run', {
    p_city_id: cityId,
    p_csv: payload,
  });

  if (error) return { ok: false, error: error.message };

  const diff =
    data && typeof data === 'object' && 'diff' in data && Array.isArray((data as { diff: unknown }).diff)
      ? ((data as { diff: CorridorImportDiffRow[] }).diff ?? [])
      : [];

  return { ok: true, diff, summary: summarizeDiff(diff) };
}

export async function applyCorridorImport(
  citySlug: string,
  cityId: string,
  diff: CorridorImportDiffRow[]
): Promise<DeployActionResult> {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc('admin_import_apply', {
    p_city_id: cityId,
    p_diff: JSON.parse(JSON.stringify(diff)) as Json,
  });

  if (error) return { ok: false, error: error.message };

  const created =
    data && typeof data === 'object' && 'created' in data
      ? Number((data as { created: number }).created)
      : 0;
  const skipped =
    data && typeof data === 'object' && 'skipped' in data
      ? Number((data as { skipped: number }).skipped)
      : 0;

  revalidatePath(`/${citySlug}/deploy`);
  revalidatePath(`/${citySlug}/graph`);
  revalidatePath(`/${citySlug}/dashboard`);

  return { ok: true, created, skipped };
}

export async function applyParksImport(
  citySlug: string,
  cityId: string,
  rows: ParkImportDiffRow[]
): Promise<DeployActionResult> {
  const toCreate = rows.filter((r) => r.action === 'create');
  if (toCreate.length === 0) {
    return { ok: true, created: 0, skipped: rows.length };
  }

  const supabase = await createClient();
  let created = 0;
  const skipped = rows.length - toCreate.length;

  for (const row of toCreate) {
    const { data: source, error: sourceError } = await supabase
      .from('data_sources')
      .insert({
        source_type: 'import',
        notes: `city_playbook_csv:${citySlug}:${row.name}`,
      })
      .select('id')
      .single();

    if (sourceError || !source) {
      return { ok: false, error: sourceError?.message ?? 'Failed to create data source.' };
    }

    const { error: parkError } = await supabase.from('parks').insert({
      city_id: cityId,
      name: row.name,
      name_aliases: row.aliases,
      location: {
        type: 'Point',
        coordinates: [row.lng, row.lat],
      },
      source_id: source.id,
      verification_status: 'candidate',
      confidence_score: 0.3,
    });

    if (parkError) {
      return { ok: false, error: parkError.message };
    }

    created += 1;
  }

  revalidatePath(`/${citySlug}/deploy`);
  revalidatePath(`/${citySlug}/graph`);

  return { ok: true, created, skipped };
}

export async function advanceCityStatus(
  citySlug: string,
  cityId: string,
  nextStatus: 'alpha' | 'beta' | 'live'
): Promise<{ ok: true } | { ok: false; error: string }> {
  const supabase = await createClient();
  const { error } = await supabase.from('cities').update({ status: nextStatus }).eq('id', cityId);

  if (error) return { ok: false, error: error.message };

  revalidatePath(`/${citySlug}/deploy`);
  return { ok: true };
}
