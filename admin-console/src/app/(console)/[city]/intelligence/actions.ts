'use server';

import { revalidatePath } from 'next/cache';
import { createClient } from '@/lib/supabase/server';

export type IntelligenceActionResult =
  | { ok: true; message: string; payload?: Record<string, unknown> }
  | { ok: false; error: string; code?: string };

function rpcErrorMessage(error: { message: string; code?: string }): IntelligenceActionResult {
  return { ok: false, error: error.message, code: error.code };
}

async function reviewIntelligence(
  citySlug: string,
  rpc:
    | 'admin_review_candidate_park'
    | 'admin_review_route_inference'
    | 'admin_review_geometry_correction',
  id: string,
  action: 'promote' | 'dismiss'
): Promise<IntelligenceActionResult> {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc(rpc, { id, action });

  if (error) return rpcErrorMessage(error);

  revalidatePath(`/${citySlug}/intelligence`);
  revalidatePath(`/${citySlug}/graph`);

  const payload = (data ?? {}) as Record<string, unknown>;
  const status = String(payload.status ?? action);
  return {
    ok: true,
    message: `${rpc.replace('admin_review_', '')} ${action} → ${status}.`,
    payload,
  };
}

export async function reviewCandidatePark(
  citySlug: string,
  id: string,
  action: 'promote' | 'dismiss'
): Promise<IntelligenceActionResult> {
  return reviewIntelligence(citySlug, 'admin_review_candidate_park', id, action);
}

export async function reviewRouteInference(
  citySlug: string,
  id: string,
  action: 'promote' | 'dismiss'
): Promise<IntelligenceActionResult> {
  return reviewIntelligence(citySlug, 'admin_review_route_inference', id, action);
}

export async function reviewGeometryCorrection(
  citySlug: string,
  id: string,
  action: 'promote' | 'dismiss'
): Promise<IntelligenceActionResult> {
  return reviewIntelligence(citySlug, 'admin_review_geometry_correction', id, action);
}
