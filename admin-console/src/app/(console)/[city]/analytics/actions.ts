'use server';

import { createClient } from '@/lib/supabase/server';
import type { CorridorAnalyticsResponse } from '@/lib/analytics/types';

export async function loadCorridorAnalyticsPage(
  corridorId: string,
  cursor: string | null
): Promise<{ ok: boolean; data?: CorridorAnalyticsResponse; error?: string }> {
  const supabase = await createClient();
  const to = new Date();
  const from = new Date(to.getTime() - 24 * 60 * 60 * 1000);

  const { data, error } = await supabase.rpc('admin_corridor_analytics', {
    p_corridor_id: corridorId,
    p_from: from.toISOString(),
    p_to: to.toISOString(),
    p_cursor: cursor ?? undefined,
    p_limit: undefined,
  });

  if (error) {
    return { ok: false, error: error.message };
  }

  return { ok: true, data: data as unknown as CorridorAnalyticsResponse };
}
