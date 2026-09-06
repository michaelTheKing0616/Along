'use server';

import { revalidatePath } from 'next/cache';
import { createClient } from '@/lib/supabase/server';

export type IntegrityActionResult =
  | { ok: true; message: string }
  | { ok: false; error: string };

export async function clearIntegrityFlag(
  citySlug: string,
  flagId: string,
  note?: string
): Promise<IntegrityActionResult> {
  const supabase = await createClient();
  const { error } = await supabase.rpc('admin_review_flag', {
    p_flag_id: flagId,
    p_action: 'clear',
    p_note: note?.trim() || undefined,
  });

  if (error) return { ok: false, error: error.message };

  revalidatePath(`/${citySlug}/integrity`);
  return { ok: true, message: 'Flag cleared.' };
}

export async function transitionStandingAndActionFlag(
  citySlug: string,
  flagId: string,
  driverId: string,
  toStanding: string,
  reason: string,
  note?: string
): Promise<IntegrityActionResult> {
  const supabase = await createClient();

  const { data: transitionData, error: transitionError } = await supabase.rpc(
    'admin_transition_standing',
    {
      p_driver_id: driverId,
      p_to: toStanding,
      p_reason: reason.trim(),
    }
  );

  if (transitionError) return { ok: false, error: transitionError.message };

  const transitionId = (transitionData as { transition_id?: number } | null)?.transition_id;
  if (transitionId == null) {
    return { ok: false, error: 'Standing transition did not return an id.' };
  }

  const { error: flagError } = await supabase.rpc('admin_review_flag', {
    p_flag_id: flagId,
    p_action: 'action',
    p_note: note?.trim() || undefined,
    p_standing_transition_id: transitionId,
  });

  if (flagError) return { ok: false, error: flagError.message };

  revalidatePath(`/${citySlug}/integrity`);
  revalidatePath(`/${citySlug}/drivers/${driverId}`);
  return { ok: true, message: 'Standing updated and flag marked actioned.' };
}
