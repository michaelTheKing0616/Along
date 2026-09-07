'use server';

import { revalidatePath } from 'next/cache';
import { createClient } from '@/lib/supabase/server';
import { rpcUntyped } from '@/lib/supabase/untyped';

export type CorporateActionResult =
  | { ok: true; message: string; payload?: Record<string, unknown> }
  | { ok: false; error: string; code?: string };

function rpcError(error: { message: string; code?: string }): CorporateActionResult {
  return { ok: false, error: error.message, code: error.code };
}

export async function inviteCorporateMember(
  citySlug: string,
  input: {
    phoneE164: string;
    department?: string;
    employeeRef?: string;
    defaultPolicyId?: string;
  }
): Promise<CorporateActionResult> {
  const supabase = await createClient();
  const { data, error } = await rpcUntyped(supabase, 'corporate_invite_member', {
    p_phone_e164: input.phoneE164,
    p_department: input.department ?? null,
    p_employee_ref: input.employeeRef ?? null,
    p_default_policy_id: input.defaultPolicyId ?? null,
  });

  if (error) return rpcError(error);

  revalidatePath(`/${citySlug}/corporate`);
  return {
    ok: true,
    message: 'Staff member added to roster.',
    payload: (data ?? {}) as Record<string, unknown>,
  };
}

export async function updateCorporateMember(
  citySlug: string,
  input: {
    riderId: string;
    department?: string;
    employeeRef?: string;
    defaultPolicyId?: string | null;
    active?: boolean;
  }
): Promise<CorporateActionResult> {
  const supabase = await createClient();
  const { data, error } = await rpcUntyped(supabase, 'corporate_update_member', {
    p_rider_id: input.riderId,
    p_department: input.department ?? null,
    p_employee_ref: input.employeeRef ?? null,
    p_default_policy_id: input.defaultPolicyId ?? null,
    p_active: input.active ?? null,
  });

  if (error) return rpcError(error);

  revalidatePath(`/${citySlug}/corporate`);
  return {
    ok: true,
    message: 'Roster updated.',
    payload: (data ?? {}) as Record<string, unknown>,
  };
}

export async function upsertCorporatePolicy(
  citySlug: string,
  input: {
    id?: string;
    name: string;
    subsidyPct: number;
    maxPerTrip?: number | null;
    allowedHoursJson?: string;
    active?: boolean;
  }
): Promise<CorporateActionResult> {
  let allowedHours: Record<string, unknown> | null = null;
  if (input.allowedHoursJson?.trim()) {
    try {
      allowedHours = JSON.parse(input.allowedHoursJson) as Record<string, unknown>;
    } catch {
      return { ok: false, error: 'Allowed hours must be valid JSON.' };
    }
  }

  const supabase = await createClient();
  const { data, error } = await rpcUntyped(supabase, 'corporate_upsert_policy', {
    p_name: input.name,
    p_subsidy_pct: input.subsidyPct,
    p_id: input.id ?? null,
    p_max_per_trip: input.maxPerTrip ?? null,
    p_allowed_hours: allowedHours,
    p_active: input.active ?? true,
  });

  if (error) return rpcError(error);

  revalidatePath(`/${citySlug}/corporate`);
  return {
    ok: true,
    message: input.id ? 'Policy updated.' : 'Policy created.',
    payload: (data ?? {}) as Record<string, unknown>,
  };
}
