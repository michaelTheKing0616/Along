'use server';

import { revalidatePath } from 'next/cache';
import { createClient } from '@/lib/supabase/server';

export type DriverActionResult =
  | { ok: true; message: string; requestId?: string; status?: string }
  | { ok: false; error: string };

export async function postManualAdjustment(
  citySlug: string,
  driverId: string,
  amount: number,
  memo: string
): Promise<DriverActionResult> {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc('admin_manual_ledger_adjustment', {
    p_driver_id: driverId,
    p_amount: amount,
    p_memo: memo.trim(),
  });

  if (error) return { ok: false, error: error.message };

  const body = data as { status?: string; request_id?: string } | null;
  revalidatePath(`/${citySlug}/drivers/${driverId}`);
  revalidatePath(`/${citySlug}/finance`);

  if (body?.status === 'pending') {
    return {
      ok: true,
      message: 'Adjustment submitted for dual-control approval.',
      requestId: body.request_id,
      status: 'pending',
    };
  }

  return { ok: true, message: 'Adjustment posted to ledger.', status: 'posted' };
}

export async function transitionDriverStanding(
  citySlug: string,
  driverId: string,
  toStanding: string,
  reason: string
): Promise<DriverActionResult> {
  const supabase = await createClient();
  const { error } = await supabase.rpc('admin_transition_standing', {
    p_driver_id: driverId,
    p_to: toStanding,
    p_reason: reason.trim(),
  });

  if (error) return { ok: false, error: error.message };

  revalidatePath(`/${citySlug}/drivers/${driverId}`);
  return { ok: true, message: 'Standing updated.' };
}

export async function notifyGuarantor(
  citySlug: string,
  driverId: string
): Promise<DriverActionResult> {
  const supabase = await createClient();
  const { error } = await supabase.rpc('admin_notify_guarantor', {
    p_driver_id: driverId,
  });

  if (error) return { ok: false, error: error.message };

  revalidatePath(`/${citySlug}/drivers/${driverId}`);
  return { ok: true, message: 'Guarantor notification sent.' };
}
