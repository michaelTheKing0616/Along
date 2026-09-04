'use server';

import { revalidatePath } from 'next/cache';
import { createClient } from '@/lib/supabase/server';
import type { ParkImportDiffRow } from '@/lib/deploy/csv-parks';

export type DeployActionResult =
  | { ok: true; created: number; skipped: number }
  | { ok: false; error: string };

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
