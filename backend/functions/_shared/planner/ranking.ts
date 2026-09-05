import type { Metrics, ModeRow, PlanCandidate, PlannerCfg, SortOrders } from '../types.ts';

const EPS = 1e-9;

function normalise(value: number, values: number[]): number {
  if (values.length === 0) return 0;
  const min = Math.min(...values);
  const max = Math.max(...values);
  const span = Math.max(max - min, EPS);
  return (value - min) / span;
}

function fareAmount(c: PlanCandidate): number {
  return Number(c.metrics.total_fare.amount);
}

export function applyRanking(
  candidates: PlanCandidate[],
  cfg: PlannerCfg,
): { candidates: PlanCandidate[]; sortOrders: SortOrders } {
  if (candidates.length === 0) {
    return {
      candidates,
      sortOrders: {
        recommended: [],
        cheapest: [],
        fastest: [],
        least_strenuous: [],
      },
    };
  }

  const fares = candidates.map((c) => fareAmount(c));
  const times = candidates.map((c) => c.metrics.total_time_s);
  const strenuous = candidates.map((c) => c.metrics.strenuousness_score);

  const scored = candidates.map((c, i) => {
    const explain = {
      fare: cfg.recommendedWeights.fare * normalise(fares[i], fares),
      time: cfg.recommendedWeights.time * normalise(times[i], times),
      strenuous: cfg.recommendedWeights.strenuous *
        normalise(strenuous[i], strenuous),
    };
    const recommended_score = explain.fare + explain.time + explain.strenuous;
    return {
      ...c,
      metrics: {
        ...c.metrics,
        recommended_score,
        explain,
      },
    };
  });

  const multiLegTimes = scored
    .filter((c) => c.kind === 'multi_leg')
    .map((c) => c.metrics.total_time_s);
  const bestAlt = multiLegTimes.length > 0 ? Math.min(...multiLegTimes) : Infinity;

  const withViability = scored.map((c) => {
    if (c.kind !== 'direct') return { ...c, viable_direct: false };
    const viable = c.metrics.total_time_s <=
      cfg.directViabilityFactor * bestAlt + cfg.directViabilitySlackS;
    return { ...c, viable_direct: viable };
  });

  const cheapest = [...withViability].sort((a, b) => {
    const df = fareAmount(a) - fareAmount(b);
    if (df !== 0) return df;
    return a.metrics.total_time_s - b.metrics.total_time_s;
  });

  const fastest = [...withViability].sort((a, b) => {
    const dt = a.metrics.total_time_s - b.metrics.total_time_s;
    if (dt !== 0) return dt;
    return fareAmount(a) - fareAmount(b);
  });

  const leastStrenuous = [...withViability].sort((a, b) => {
    const ds = a.metrics.strenuousness_score - b.metrics.strenuousness_score;
    if (ds !== 0) return ds;
    const dt = a.metrics.transfer_count - b.metrics.transfer_count;
    if (dt !== 0) return dt;
    return fareAmount(a) - fareAmount(b);
  });

  const recommendedBase = [...withViability].sort((a, b) => {
    const dr = a.metrics.recommended_score - b.metrics.recommended_score;
    if (dr !== 0) return dr;
    return a.metrics.total_time_s - b.metrics.total_time_s;
  });

  const viableDirect = recommendedBase.filter((c) => c.viable_direct);
  let recommended = recommendedBase;
  if (viableDirect.length > 0) {
    const bestDirectId = viableDirect[0].candidate_id;
    recommended = [
      ...recommendedBase.filter((c) => c.candidate_id === bestDirectId),
      ...recommendedBase.filter((c) => c.candidate_id !== bestDirectId),
    ];
  }

  const limited = recommended.slice(0, cfg.maxCandidates);
  const allowed = new Set(limited.map((c) => c.candidate_id));

  const filterSort = (list: PlanCandidate[]) =>
    list.filter((c) => allowed.has(c.candidate_id)).map((c) => c.candidate_id);

  return {
    candidates: limited,
    sortOrders: {
      recommended: filterSort(recommended),
      cheapest: filterSort(cheapest),
      fastest: filterSort(fastest),
      least_strenuous: filterSort(leastStrenuous),
    },
  };
}

export function computeMetrics(input: {
  walkTotalM: number;
  walkS: number;
  waitS: number;
  inVehicleS: number;
  transferCount: number;
  totalFare: { amount: string; currency: string };
  mode: ModeRow;
  cfg: PlannerCfg;
}): Omit<Metrics, 'recommended_score' | 'explain'> {
  const strenuousness =
    input.cfg.strenuousWeights.transfer * input.transferCount +
    input.cfg.strenuousWeights.walk_per_100m * (input.walkTotalM / 100) +
    input.cfg.strenuousWeights.mode * (input.mode.comfort_weight / 10);

  return {
    total_fare: input.totalFare,
    total_time_s: input.walkS + input.waitS + input.inVehicleS,
    in_vehicle_s: input.inVehicleS,
    wait_s: input.waitS,
    walk_s: input.walkS,
    transfer_count: input.transferCount,
    total_walking_distance_m: Math.round(input.walkTotalM),
    strenuousness_score: strenuousness,
  };
}

export function loadWarning(
  modeCapacity: string,
  loadSize: string | undefined,
  warnCapacities: Record<string, string[]>,
): { reason: string; mode_capacity: string } | null {
  if (!loadSize || !warnCapacities[loadSize]) return null;
  if (warnCapacities[loadSize].includes(modeCapacity)) {
    return { reason: 'mode_capacity', mode_capacity: modeCapacity };
  }
  return null;
}

export function parkedWaitS(mode: ModeRow): number {
  return Math.round(mode.default_dwell_s / 2);
}
