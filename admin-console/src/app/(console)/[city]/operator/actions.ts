'use server';

import { createClient } from '@/lib/supabase/server';
import { rpcUntyped } from '@/lib/supabase/untyped';
import type { OperatorOverview } from '@/lib/operator/types';

export type OperatorActionResult =
  | { ok: true; overview: OperatorOverview }
  | { ok: false; error: string };

export async function loadOperatorOverview(
  fromIso: string,
  toIso: string
): Promise<OperatorActionResult> {
  const supabase = await createClient();
  const { data, error } = await rpcUntyped(supabase, 'operator_overview', {
    p_from: fromIso,
    p_to: toIso,
  });

  if (error) {
    return { ok: false, error: error.message };
  }

  return { ok: true, overview: data as OperatorOverview };
}
