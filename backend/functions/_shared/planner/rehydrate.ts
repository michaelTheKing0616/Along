import type { SupabaseClient } from '@supabase/supabase-js';
import type {
  Fare,
  FareComponent,
  PlanCandidate,
  PlanTripFilters,
  SortOrders,
} from '../types.ts';

type FareResolution = {
  quote_id: string;
  amount: number;
  currency: string;
  tier: number;
  confidence: number;
  components: Array<{ kind: string; amount: number; ref_id?: string }>;
  unconfirmed: boolean;
};

function mapFare(res: FareResolution, expiresAt: string): Fare {
  const components: FareComponent[] = (res.components ?? []).map((c) => ({
    kind: c.kind,
    ref_id: c.ref_id,
    label: c.kind.replace(/_/g, ' '),
    amount: { amount: Number(c.amount).toFixed(2), currency: res.currency },
  }));
  return {
    total: { amount: res.amount.toFixed(2), currency: res.currency },
    tier: res.tier,
    confidence: res.confidence,
    unconfirmed: res.unconfirmed,
    components,
    quote_id: res.quote_id,
    expires_at: expiresAt,
  };
}

/** Shareable plan-trip payload (no rider-specific query_id or fare quote_ids). */
export type ShareablePlanTripCache = {
  city_id: string;
  degraded: boolean;
  candidates: PlanCandidate[];
  sort_orders: SortOrders;
  coverage_gap: Record<string, unknown> | null;
};

export function toShareablePlanTripCache(
  data: Record<string, unknown>,
): ShareablePlanTripCache {
  const { query_id: _queryId, ...shareable } = data;
  return shareable as ShareablePlanTripCache;
}

async function resolveLegFare(
  service: SupabaseClient,
  candidate: PlanCandidate,
  leg: PlanCandidate['legs'][number],
  cityId: string,
  riderId: string,
  filters: PlanTripFilters,
): Promise<FareResolution | null> {
  const loadJson = filters.load.flagged
    ? { flagged: true, size: filters.load.size ?? null }
    : null;

  const board = leg.board as { stage_id: string };
  const alight = leg.alight as { stage_id: string };

  const fareArgs: Record<string, unknown> = {
    p_mode_code: leg.mode.code,
    p_city_id: cityId,
    p_load: loadJson,
    p_rider_id: riderId,
    p_from_stage_id: board.stage_id,
    p_to_stage_id: alight.stage_id,
  };

  const profileId = (leg.supply as { profile_id?: string })?.profile_id;
  if (candidate.source === 'driver_profile' && profileId) {
    fareArgs.p_profile_id = profileId;
  } else if (leg.route_id) {
    fareArgs.p_route_id = leg.route_id;
  } else {
    return null;
  }

  const { data: fareData, error: fareError } = await service.rpc(
    'resolve_fare',
    fareArgs,
  );
  if (fareError || !fareData) return null;
  return fareData as FareResolution;
}

/** Re-resolve fares for the current rider; preserve cached ranking structure. */
export async function rehydratePlanTripCandidates(
  service: SupabaseClient,
  cached: ShareablePlanTripCache,
  riderId: string,
  filters: PlanTripFilters,
): Promise<PlanCandidate[] | null> {
  const candidates = structuredClone(cached.candidates);

  for (const candidate of candidates) {
    let totalFareAmount = 0;
    let currency = 'NGN';

    for (const leg of candidate.legs) {
      const fareRes = await resolveLegFare(
        service,
        candidate,
        leg,
        cached.city_id,
        riderId,
        filters,
      );
      if (!fareRes) return null;

      currency = fareRes.currency;
      totalFareAmount += Number(fareRes.amount);
      const expiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString();
      leg.fare = mapFare(fareRes, expiresAt);
    }

    if (candidate.kind === 'multi_leg') {
      candidate.metrics.total_fare = {
        amount: totalFareAmount.toFixed(2),
        currency,
      };
    } else if (candidate.legs[0]) {
      candidate.metrics.total_fare = candidate.legs[0].fare.total;
    }
  }

  return candidates;
}
