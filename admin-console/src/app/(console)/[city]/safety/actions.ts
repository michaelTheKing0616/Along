'use server';

import { revalidatePath } from 'next/cache';
import { createClient } from '@/lib/supabase/server';

export type SafetyActionResult =
  | { ok: true; message: string }
  | { ok: false; error: string };

export async function acknowledgeSos(
  citySlug: string,
  sosId: string
): Promise<SafetyActionResult> {
  const supabase = await createClient();
  const { error } = await supabase.rpc('admin_ack_sos', { p_id: sosId });

  if (error) return { ok: false, error: error.message };

  revalidatePath(`/${citySlug}/safety`);
  return { ok: true, message: 'SOS acknowledged — raiser notified.' };
}

export async function resolveSos(
  citySlug: string,
  sosId: string,
  status: 'resolved' | 'false_alarm',
  note?: string
): Promise<SafetyActionResult> {
  const supabase = await createClient();
  const { error } = await supabase.rpc('admin_resolve_sos', {
    p_id: sosId,
    p_status: status,
    p_note: note?.trim() || undefined,
  });

  if (error) return { ok: false, error: error.message };

  revalidatePath(`/${citySlug}/safety`);
  return { ok: true, message: `SOS marked ${status.replace('_', ' ')}.` };
}

export async function triageIncident(
  citySlug: string,
  incidentId: string,
  status: string,
  assignedTo?: string | null,
  severity?: number
): Promise<SafetyActionResult> {
  const supabase = await createClient();
  const { error } = await supabase.rpc('admin_triage_incident', {
    p_id: incidentId,
    p_status: status,
    p_assigned_to: assignedTo || undefined,
    p_severity: severity,
  });

  if (error) return { ok: false, error: error.message };

  revalidatePath(`/${citySlug}/safety`);
  return { ok: true, message: 'Incident updated.' };
}
