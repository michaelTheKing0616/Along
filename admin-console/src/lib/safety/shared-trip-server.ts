import { createClient } from '@supabase/supabase-js';
import type { Database } from '@along/contracts/db.types';
import type { SharedTripViewPayload } from './shared-trip-types';

export async function fetchSharedTripView(token: string): Promise<SharedTripViewPayload> {
  const supabase = createClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  );

  const { data, error } = await supabase.rpc('shared_trip_view', {
    p_token: token,
  });

  if (error) {
    throw new Error(error.message);
  }

  return data as unknown as SharedTripViewPayload;
}

export function formatEtaMinutes(etaSeconds: number): string {
  const minutes = Math.max(1, Math.round(etaSeconds / 60));
  return `${minutes} min`;
}

export function modeLabel(code: string, label?: string): string {
  return label ?? code;
}
