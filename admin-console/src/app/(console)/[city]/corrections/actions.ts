'use server';

import { revalidatePath } from 'next/cache';
import { createClient } from '@/lib/supabase/server';

export type CorrectionActionResult =
  | { ok: true; message: string; confirmationId?: string; promoted?: boolean }
  | { ok: false; error: string; code?: string };

export async function approveFareCorrection(
  citySlug: string,
  correctionId: string,
  note?: string
): Promise<CorrectionActionResult> {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc('admin_review_fare_correction', {
    id: correctionId,
    action: 'approve',
    note: note?.trim() || undefined,
  });

  if (error) return { ok: false, error: error.message, code: error.code };

  const body = data as {
    confirmation_id?: string;
    promoted?: boolean;
  } | null;

  revalidatePath(`/${citySlug}/corrections`);

  const promoted = Boolean(body?.promoted);
  return {
    ok: true,
    confirmationId: body?.confirmation_id ?? undefined,
    promoted,
    message: promoted
      ? 'Correction approved — graph confirmation recorded and entity promoted.'
      : 'Correction approved — graph confirmation recorded.',
  };
}

export async function rejectFareCorrection(
  citySlug: string,
  correctionId: string,
  note?: string
): Promise<CorrectionActionResult> {
  const supabase = await createClient();
  const { error } = await supabase.rpc('admin_review_fare_correction', {
    id: correctionId,
    action: 'reject',
    note: note?.trim() || undefined,
  });

  if (error) return { ok: false, error: error.message, code: error.code };

  revalidatePath(`/${citySlug}/corrections`);
  return { ok: true, message: 'Correction rejected.' };
}
