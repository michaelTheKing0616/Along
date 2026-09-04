'use server';

import type { Json } from '@along/contracts/db.types';
import { revalidatePath } from 'next/cache';
import { createClient } from '@/lib/supabase/server';

export type FieldActionResult =
  | { ok: true; message: string }
  | { ok: false; error: string; code?: string };

function rpcErrorMessage(error: { message: string; code?: string }): FieldActionResult {
  if (error.code === '0A000') {
    return {
      ok: false,
      code: '0A000',
      error:
        'Publish for this entity type is not yet supported — park publish works; route/stage publish is deferred.',
    };
  }
  return { ok: false, error: error.message, code: error.code };
}

export async function reconcileFieldEntity(
  citySlug: string,
  reconciliationId: string,
  action: 'match' | 'discrepant' | 'resolve' | 'reject',
  resolution?: { payload: Record<string, unknown> }
): Promise<FieldActionResult> {
  const supabase = await createClient();
  const { error } = await supabase.rpc('admin_reconcile_field_entity', {
    p_reconciliation_id: reconciliationId,
    p_action: action,
    p_resolution: (resolution ?? undefined) as Json | undefined,
  });

  if (error) return rpcErrorMessage(error);

  revalidatePath(`/${citySlug}/field`);
  return { ok: true, message: `Reconciliation marked ${action}.` };
}

export async function publishFieldEntity(
  citySlug: string,
  reconciliationId: string
): Promise<FieldActionResult> {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc('admin_publish_field_entity', {
    p_reconciliation_id: reconciliationId,
  });

  if (error) return rpcErrorMessage(error);

  revalidatePath(`/${citySlug}/field`);
  revalidatePath(`/${citySlug}/graph`);

  const target = data as { target_type?: string; target_id?: string } | null;
  return {
    ok: true,
    message: target?.target_type
      ? `Published ${target.target_type} ${target.target_id ?? ''} as field_verified.`
      : 'Published to field_verified.',
  };
}
