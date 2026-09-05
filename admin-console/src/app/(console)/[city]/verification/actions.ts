'use server';

import { revalidatePath } from 'next/cache';
import { createClient } from '@/lib/supabase/server';

export type VerificationActionResult =
  | { ok: true; message: string }
  | { ok: false; error: string; code?: string };

export async function approveVerification(
  citySlug: string,
  verificationId: string,
  womenOnlyEligible?: boolean
): Promise<VerificationActionResult> {
  const supabase = await createClient();
  const { error } = await supabase.rpc('admin_approve_verification', {
    p_verification_id: verificationId,
    p_women_only_eligible: womenOnlyEligible ?? undefined,
  });

  if (error) {
    if (error.message.includes('DUPLICATE_IDENTITY')) {
      return {
        ok: false,
        code: 'DUPLICATE_IDENTITY',
        error: 'Duplicate identity hash — ops_lead approval required.',
      };
    }
    return { ok: false, error: error.message, code: error.code };
  }

  revalidatePath(`/${citySlug}/verification`);
  return { ok: true, message: 'Document approved.' };
}

export async function rejectVerification(
  citySlug: string,
  verificationId: string,
  reason: string
): Promise<VerificationActionResult> {
  const trimmed = reason.trim();
  if (!trimmed) {
    return { ok: false, error: 'Rejection reason is required.' };
  }

  const supabase = await createClient();
  const { error } = await supabase.rpc('admin_reject_verification', {
    p_verification_id: verificationId,
    p_reason: trimmed,
  });

  if (error) return { ok: false, error: error.message, code: error.code };

  revalidatePath(`/${citySlug}/verification`);
  return { ok: true, message: 'Document rejected.' };
}
