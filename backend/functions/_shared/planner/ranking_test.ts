import { assertEquals } from 'jsr:@std/assert@1';
import {
  applyRanking,
  computeMetrics,
  loadWarning,
} from './ranking.ts';
import type { Metrics, ModeRow, PlanCandidate } from '../types.ts';

const mode: ModeRow = {
  code: 'okada',
  label: 'Okada',
  icon_key: 'mode.okada',
  color_token: 'mode.okada',
  comfort_weight: 8,
  load_capacity: 'none',
  default_dwell_s: 120,
};

const cfg = {
  maxCandidates: 12,
  walkSpeedMps: 1.25,
  sharedVehicleFactor: 1.25,
  defaultWaitS: 300,
  directViabilityFactor: 1.5,
  directViabilitySlackS: 300,
  baselineSpeedMps: 8.33,
  speedProfileMinSamples: 8,
  recommendedWeights: { fare: 0.4, time: 0.4, strenuous: 0.2 },
  strenuousWeights: { transfer: 1, walk_per_100m: 0.25, mode: 0.5 },
  warnCapacities: {
    small: ['none'],
    medium: ['none', 'small'],
    large: ['none', 'small', 'medium'],
  },
};

function candidate(id: string, fare: number, time: number): PlanCandidate {
  const partial = computeMetrics({
    walkTotalM: 200,
    walkS: 160,
    waitS: 120,
    inVehicleS: time,
    transferCount: 0,
    totalFare: { amount: fare.toFixed(2), currency: 'NGN' },
    mode,
    cfg,
  });
  const metrics: Metrics = {
    ...partial,
    recommended_score: 0,
    explain: { fare: 0, time: 0, strenuous: 0 },
  };
  return {
    candidate_id: id,
    kind: 'direct',
    source: 'graph',
    viable_direct: true,
    legs: [],
    transfers: [],
    metrics,
  };
}

Deno.test('TS-PLAN-02 ranking: slow direct unviable when fast multi-leg exists', () => {
  const slowDirect = candidate('slow', 400, 5400);
  slowDirect.kind = 'direct';
  const fastMulti = candidate('fast', 500, 1400);
  fastMulti.kind = 'multi_leg';
  fastMulti.metrics.transfer_count = 1;
  fastMulti.viable_direct = false;

  const { candidates, sortOrders } = applyRanking([slowDirect, fastMulti], cfg);
  const direct = candidates.find((c) => c.candidate_id === 'slow');
  const multi = candidates.find((c) => c.candidate_id === 'fast');
  assertEquals(direct?.viable_direct, false);
  assertEquals(sortOrders.recommended[0], multi?.candidate_id);
});

Deno.test('TS-PLAN-01 direct-only: recommended[0] is viable direct', () => {
  const a = candidate('a', 400, 900);
  const b = candidate('b', 200, 1200);
  const { sortOrders, candidates } = applyRanking([a, b], cfg);

  assertEquals(candidates.every((c) => c.viable_direct), true);
  assertEquals(sortOrders.recommended[0], candidates[0].candidate_id);
  assertEquals(candidates[0].kind, 'direct');
});

Deno.test('TS-PLAN-08: load large + okada keeps candidate with load_warning', () => {
  const warning = loadWarning('none', 'large', cfg.warnCapacities);
  assertEquals(warning, { reason: 'mode_capacity', mode_capacity: 'none' });

  const noWarning = loadWarning('large', 'small', cfg.warnCapacities);
  assertEquals(noWarning, null);
});

Deno.test('metrics explain sums to recommended_score', () => {
  const { candidates } = applyRanking([candidate('x', 300, 800)], cfg);
  const m = candidates[0]!.metrics;
  const sum = Object.values(m.explain).reduce((a: number, b: number) => a + b, 0);
  assertEquals(Math.abs(sum - m.recommended_score) < 1e-6, true);
});
