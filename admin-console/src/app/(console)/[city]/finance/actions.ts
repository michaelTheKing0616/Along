'use server';

import { revalidatePath } from 'next/cache';
import { createClient } from '@/lib/supabase/server';

export type FinanceActionResult =
  | { ok: true; message: string }
  | { ok: false; error: string };

export async function approvePendingAdjustment(
  citySlug: string,
  requestId: string
): Promise<FinanceActionResult> {
  const supabase = await createClient();
  const { error } = await supabase.rpc('admin_approve_adjustment', {
    p_request_id: requestId,
  });

  if (error) return { ok: false, error: error.message };

  revalidatePath(`/${citySlug}/finance`);
  return { ok: true, message: 'Adjustment approved and posted.' };
}

export async function upsertSettlementAgent(
  citySlug: string,
  cityId: string,
  input: {
    id?: string;
    businessName: string;
    phone: string;
    lat?: number;
    lng?: number;
    active: boolean;
  }
): Promise<FinanceActionResult> {
  const supabase = await createClient();
  const { error } = await supabase.rpc(
    'admin_upsert_settlement_agent',
    {
      p_id: input.id ?? null,
      p_business_name: input.businessName.trim(),
      p_city_id: cityId,
      p_agent_phone: input.phone.trim(),
      p_lat: input.lat ?? undefined,
      p_lng: input.lng ?? undefined,
      p_active: input.active,
    } as {
      p_id: string;
      p_business_name: string;
      p_city_id: string;
      p_agent_phone: string;
      p_lat?: number;
      p_lng?: number;
      p_active?: boolean;
    }
  );

  if (error) return { ok: false, error: error.message };

  revalidatePath(`/${citySlug}/finance`);
  return { ok: true, message: input.id ? 'Agent updated.' : 'Agent created.' };
}

export async function initiatePayout(
  citySlug: string,
  driverId: string
): Promise<FinanceActionResult> {
  const supabase = await createClient();
  const { error } = await supabase.rpc('admin_payout_positive_balance', {
    p_driver_id: driverId,
  });

  if (error) return { ok: false, error: error.message };

  revalidatePath(`/${citySlug}/finance`);
  return { ok: true, message: 'Payout initiated.' };
}
