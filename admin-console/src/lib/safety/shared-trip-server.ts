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

/** Prefer the shared estimator payload. Fall back to eta_s for older links. */
export function sharedEtaLabel(view: {
  eta?: {
    status?: string;
    trip?: { label?: string } | null;
    pickup?: { label?: string } | null;
  } | null;
  eta_s?: number | null;
}): string {
  if (view.eta?.status === 'calculating') return 'Calculating…';
  const label = view.eta?.trip?.label ?? view.eta?.pickup?.label;
  if (label) return label;
  if (view.eta_s == null) return 'Calculating…';
  return formatEtaMinutes(view.eta_s);
}

export function modeLabel(code: string, label?: string): string {
  return label ?? code;
}
