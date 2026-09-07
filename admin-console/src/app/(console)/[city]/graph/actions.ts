'use server';

import type { Json } from '@along/contracts/db.types';
import { revalidatePath } from 'next/cache';
import { createClient } from '@/lib/supabase/server';
import type { PendingGraphChange } from '@/lib/graph/types';
import { rpcGraphType } from '@/lib/graph/types';

export type GraphActionResult =
  | { ok: true; revisionId: number | null; message: string }
  | { ok: false; error: string };

export type ImportActionResult =
  | { ok: true; diff: Array<Record<string, unknown>> }
  | { ok: false; error: string };

export async function saveGraphEntity(
  citySlug: string,
  change: PendingGraphChange
): Promise<GraphActionResult> {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc('admin_update_graph_entity', {
    p_type: rpcGraphType(change.kind),
    p_payload: { id: change.id, ...change.payload } as Json,
  });

  if (error) return { ok: false, error: error.message };

  const revisionId =
    data && typeof data === 'object' && 'revision_id' in data
      ? Number((data as { revision_id: number | null }).revision_id)
      : null;

  revalidatePath(`/${citySlug}/graph`);
  return {
    ok: true,
    revisionId,
    message: `Saved ${change.kind} ${change.id}${revisionId ? ` — graph revision #${revisionId}` : ''}.`,
  };
}

export async function dryRunGraphImport(
  cityId: string,
  csvText: string
): Promise<ImportActionResult> {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc('admin_import_dry_run', {
    p_city_id: cityId,
    p_csv: csvText,
  });

  if (error) return { ok: false, error: error.message };

  const diff =
    data && typeof data === 'object' && 'diff' in data && Array.isArray((data as { diff: unknown }).diff)
      ? ((data as { diff: Array<Record<string, unknown>> }).diff ?? [])
      : [];

  return { ok: true, diff };
}

export async function applyGraphImport(
  citySlug: string,
  cityId: string,
  diff: Array<Record<string, unknown>>
): Promise<{ ok: true; created: number; skipped: number } | { ok: false; error: string }> {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc('admin_import_apply', {
    p_city_id: cityId,
    p_diff: diff as Json,
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

  revalidatePath(`/${citySlug}/graph`);
  return { ok: true, created, skipped };
}
