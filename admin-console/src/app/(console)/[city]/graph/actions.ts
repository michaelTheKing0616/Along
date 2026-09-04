'use server';

import { revalidatePath } from 'next/cache';
import { createClient } from '@/lib/supabase/server';

export type GraphActionResult = { ok: true } | { ok: false; error: string };

export async function updatePark(
  citySlug: string,
  parkId: string,
  patch: { name?: string; name_aliases?: string[] }
): Promise<GraphActionResult> {
  const supabase = await createClient();
  const { error } = await supabase.from('parks').update(patch).eq('id', parkId);

  if (error) return { ok: false, error: error.message };

  revalidatePath(`/${citySlug}/graph`);
  return { ok: true };
}

export async function updateRoute(
  citySlug: string,
  routeId: string,
  patch: { name?: string | null; active?: boolean }
): Promise<GraphActionResult> {
  const supabase = await createClient();
  const { error } = await supabase.from('routes').update(patch).eq('id', routeId);

  if (error) return { ok: false, error: error.message };

  revalidatePath(`/${citySlug}/graph`);
  return { ok: true };
}

export async function updateRouteStage(
  citySlug: string,
  stageId: string,
  patch: { name?: string | null; sequence?: number }
): Promise<GraphActionResult> {
  const supabase = await createClient();
  const { error } = await supabase.from('route_stages').update(patch).eq('id', stageId);

  if (error) return { ok: false, error: error.message };

  revalidatePath(`/${citySlug}/graph`);
  return { ok: true };
}
