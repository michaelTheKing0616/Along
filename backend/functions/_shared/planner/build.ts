import type { SupabaseClient } from '@supabase/supabase-js';
import { fallbackWalkDistanceM, walkSeconds } from '../geo.ts';
import type { OsrmClient } from '../osrm.ts';
import { computeMetrics, loadWarning, parkedWaitS } from './ranking.ts';
import type {
  Fare,
  FareComponent,
  Metrics,
  ModeRow,
  PlanCandidate,
  PlanCandidateLeg,
  PlannerCfg,
  Point,
  RawDirectCandidate,
  StageRow,
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

export type RawMultiLegItinerary = {
  kind: 'multi_leg';
  origin_park_id: string;
  destination_park_id: string;
  legs: Array<{
    route_id: string;
    mode_code: string;
    from_stage_id: string;
    to_stage_id: string;
    route_leg_ids?: string[];
    in_vehicle_time_estimate_s?: number;
    avg_wait_time_estimate_s?: number;
    fare?: { amount: number; currency: string };
  }>;
  transfers: Array<{
    park_id: string;
    walk_distance_m?: number;
    transfer_time_s?: number;
  }>;
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

function stagePoint(stage: StageRow): Point {
  return { lat: stage.lat, lng: stage.lng };
}

function boardStop(stage: StageRow, walkM: number, walkS: number) {
  return {
    stage_id: stage.id,
    name: stage.name,
    location: { lat: stage.lat, lng: stage.lng },
    walk_m: Math.round(walkM),
    walk_s: walkS,
    wayfinding_available: true,
  };
}

function directSignature(c: PlanCandidate): string {
  const leg = c.legs[0];
  if (!leg) return c.candidate_id;
  return `${leg.route_id ?? ''}:${leg.board.stage_id}:${leg.alight.stage_id}`;
}

export function isDuplicateOfDirect(
  multi: PlanCandidate,
  directSignatures: Set<string>,
): boolean {
  if (multi.legs.length !== 1 || multi.transfers.length > 0) return false;
  const leg = multi.legs[0];
  const sig = `${leg.route_id ?? ''}:${leg.board.stage_id}:${leg.alight.stage_id}`;
  return directSignatures.has(sig);
}

export async function buildDirectCandidates(input: {
  service: SupabaseClient;
  osrm: OsrmClient;
  rawCandidates: RawDirectCandidate[];
  stageMap: Map<string, StageRow>;
  modeMap: Map<string, ModeRow>;
  origin: Point;
  destination: Point;
  cityId: string;
  riderId: string;
  filters: { load: { flagged: boolean; size?: string } };
  plannerCfg: PlannerCfg;
  toBoard: { distances: number[][]; durations: number[][]; degraded: boolean };
  fromAlight: { distances: number[][]; durations: number[][]; degraded: boolean };
  boardStages: string[];
  alightStages: string[];
}): Promise<{ candidates: PlanCandidate[]; degraded: boolean }> {
  let degraded = input.toBoard.degraded || input.fromAlight.degraded;
  const built: PlanCandidate[] = [];

  const boardIndex = new Map<string, number>();
  input.boardStages.forEach((id, i) => boardIndex.set(id, i));
  const alightIndex = new Map<string, number>();
  input.alightStages.forEach((id, i) => alightIndex.set(id, i));

  for (const raw of input.rawCandidates) {
    const board = input.stageMap.get(raw.board_stage_id);
    const alight = input.stageMap.get(raw.alight_stage_id);
    const mode = input.modeMap.get(raw.mode_code);
    if (!board || !alight || !mode) continue;

    const bi = boardIndex.get(raw.board_stage_id) ?? 0;
    const ai = alightIndex.get(raw.alight_stage_id) ?? 0;

    const originWalkM = input.toBoard.distances[0]?.[bi] ??
      Math.round(fallbackWalkDistanceM(input.origin, stagePoint(board)));
    const originWalkS = input.toBoard.durations[0]?.[bi] ??
      walkSeconds(originWalkM, input.plannerCfg.walkSpeedMps);

    const destWalkM = input.fromAlight.distances[ai]?.[0] ??
      Math.round(fallbackWalkDistanceM(stagePoint(alight), input.destination));
    const destWalkS = input.fromAlight.durations[ai]?.[0] ??
      walkSeconds(destWalkM, input.plannerCfg.walkSpeedMps);

    const walkTotalM = originWalkM + destWalkM;

    let inVehicleS = raw.in_vehicle_time_estimate_s ?? 0;
    if (inVehicleS <= 0 && raw.route_id) {
      const route = await input.osrm.carRoute(stagePoint(board), stagePoint(alight));
      if (route.degraded) degraded = true;
      inVehicleS = Math.round(route.durationS * input.plannerCfg.sharedVehicleFactor);
    }

    let waitS = raw.avg_wait_time_estimate_s ?? input.plannerCfg.defaultWaitS;
    if (raw.source === 'parked') {
      waitS = parkedWaitS(mode);
    }

    const loadJson = input.filters.load.flagged
      ? { flagged: true, size: input.filters.load.size ?? null }
      : null;

    const fareArgs: Record<string, unknown> = {
      p_mode_code: raw.mode_code,
      p_city_id: input.cityId,
      p_load: loadJson,
      p_rider_id: input.riderId,
    };
    if (raw.profile_id) {
      fareArgs.p_profile_id = raw.profile_id;
      fareArgs.p_from_stage_id = raw.board_stage_id;
      fareArgs.p_to_stage_id = raw.alight_stage_id;
    } else if (raw.route_id) {
      fareArgs.p_route_id = raw.route_id;
      fareArgs.p_from_stage_id = raw.board_stage_id;
      fareArgs.p_to_stage_id = raw.alight_stage_id;
    }

    const { data: fareData, error: fareError } = await input.service.rpc(
      'resolve_fare',
      fareArgs,
    );
    if (fareError || !fareData) continue;

    const fareRes = fareData as FareResolution;
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString();
    const fare = mapFare(fareRes, expiresAt);

    const warning = input.filters.load.flagged
      ? loadWarning(mode.load_capacity, input.filters.load.size, input.plannerCfg.warnCapacities)
      : null;

    const leg: PlanCandidateLeg = {
      leg_index: 0,
      mode: {
        code: mode.code,
        label: mode.label,
        icon_key: mode.icon_key,
        color_token: mode.color_token,
      },
      board: boardStop(board, originWalkM, originWalkS),
      alight: {
        stage_id: alight.id,
        name: alight.name,
        location: { lat: alight.lat, lng: alight.lng },
      },
      route_id: raw.route_id,
      route_leg_ids: raw.route_leg_ids ?? [],
      in_vehicle_s: inVehicleS,
      wait_s: waitS,
      fare,
      supply: raw.supply,
      load_warning: warning,
    };

    const walkS = originWalkS + destWalkS;
    const partial = computeMetrics({
      walkTotalM,
      walkS,
      waitS,
      inVehicleS,
      transferCount: 0,
      totalFare: fare.total,
      mode,
      cfg: input.plannerCfg,
    });
    const metrics: Metrics = {
      ...partial,
      recommended_score: 0,
      explain: { fare: 0, time: 0, strenuous: 0 },
    };

    built.push({
      candidate_id: crypto.randomUUID(),
      kind: 'direct',
      source: raw.source as PlanCandidate['source'],
      viable_direct: true,
      legs: [leg],
      transfers: [],
      metrics,
    });
  }

  return { candidates: built, degraded };
}

export async function buildMultiLegCandidates(input: {
  service: SupabaseClient;
  osrm: OsrmClient;
  itineraries: RawMultiLegItinerary[];
  stageMap: Map<string, StageRow>;
  modeMap: Map<string, ModeRow>;
  origin: Point;
  destination: Point;
  cityId: string;
  riderId: string;
  filters: { load: { flagged: boolean; size?: string } };
  plannerCfg: PlannerCfg;
  directSignatures: Set<string>;
}): Promise<{ candidates: PlanCandidate[]; degraded: boolean }> {
  let degraded = false;
  const built: PlanCandidate[] = [];

  for (const itin of input.itineraries) {
    if (!itin.legs?.length) continue;

    const legStages = itin.legs.flatMap((l) => [l.from_stage_id, l.to_stage_id]);
    for (const sid of legStages) {
      if (!input.stageMap.has(sid)) {
        const { data } = await input.service.rpc('stage_points', { p_stage_ids: [sid] });
        for (const row of (data ?? []) as StageRow[]) {
          input.stageMap.set(row.id, row);
        }
      }
    }

    const firstBoard = input.stageMap.get(itin.legs[0].from_stage_id);
    const lastAlight = input.stageMap.get(itin.legs[itin.legs.length - 1].to_stage_id);
    if (!firstBoard || !lastAlight) continue;

    const toBoard = await input.osrm.footTable([input.origin], [stagePoint(firstBoard)]);
    if (toBoard.degraded) degraded = true;
    const fromAlight = await input.osrm.footTable(
      [stagePoint(lastAlight)],
      [input.destination],
    );
    if (fromAlight.degraded) degraded = true;

    const originWalkM = toBoard.distances[0]?.[0] ??
      Math.round(fallbackWalkDistanceM(input.origin, stagePoint(firstBoard)));
    const originWalkS = toBoard.durations[0]?.[0] ??
      walkSeconds(originWalkM, input.plannerCfg.walkSpeedMps);
    const destWalkM = fromAlight.distances[0]?.[0] ??
      Math.round(fallbackWalkDistanceM(stagePoint(lastAlight), input.destination));
    const destWalkS = fromAlight.durations[0]?.[0] ??
      walkSeconds(destWalkM, input.plannerCfg.walkSpeedMps);

    let transferWalkM = 0;
    let transferS = 0;
    for (const t of itin.transfers ?? []) {
      transferWalkM += t.walk_distance_m ?? 0;
      transferS += t.transfer_time_s ?? 0;
    }
    transferS += walkSeconds(transferWalkM, input.plannerCfg.walkSpeedMps);

    const builtLegs: PlanCandidateLeg[] = [];
    let totalInVehicleS = 0;
    let totalWaitS = 0;
    let totalFareAmount = 0;
    let currency = 'NGN';
    let maxComfort = 0;
    let dominantMode: ModeRow | null = null;

    for (let i = 0; i < itin.legs.length; i++) {
      const rawLeg = itin.legs[i];
      const board = input.stageMap.get(rawLeg.from_stage_id);
      const alight = input.stageMap.get(rawLeg.to_stage_id);
      const mode = input.modeMap.get(rawLeg.mode_code);
      if (!board || !alight || !mode) {
        builtLegs.length = 0;
        break;
      }
      if (!dominantMode || mode.comfort_weight > maxComfort) {
        dominantMode = mode;
        maxComfort = mode.comfort_weight;
      }

      if (!input.modeMap.has(mode.code)) {
        input.modeMap.set(mode.code, mode);
      }

      const loadJson = input.filters.load.flagged
        ? { flagged: true, size: input.filters.load.size ?? null }
        : null;

      const { data: fareData, error: fareError } = await input.service.rpc('resolve_fare', {
        p_route_id: rawLeg.route_id,
        p_from_stage_id: rawLeg.from_stage_id,
        p_to_stage_id: rawLeg.to_stage_id,
        p_mode_code: rawLeg.mode_code,
        p_city_id: input.cityId,
        p_load: loadJson,
        p_rider_id: input.riderId,
      });
      if (fareError || !fareData) {
        builtLegs.length = 0;
        break;
      }

      const fareRes = fareData as FareResolution;
      currency = fareRes.currency;
      totalFareAmount += Number(fareRes.amount);

      const inVehicleS = rawLeg.in_vehicle_time_estimate_s ?? 0;
      const waitS = rawLeg.avg_wait_time_estimate_s ?? input.plannerCfg.defaultWaitS;
      totalInVehicleS += inVehicleS;
      totalWaitS += waitS;

      const expiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString();
      const fare = mapFare(fareRes, expiresAt);

      const walkM = i === 0 ? originWalkM : 0;
      const walkLegS = i === 0 ? originWalkS : 0;

      builtLegs.push({
        leg_index: i,
        mode: {
          code: mode.code,
          label: mode.label,
          icon_key: mode.icon_key,
          color_token: mode.color_token,
        },
        board: boardStop(board, walkM, walkLegS),
        alight: {
          stage_id: alight.id,
          name: alight.name,
          location: { lat: alight.lat, lng: alight.lng },
        },
        route_id: rawLeg.route_id,
        route_leg_ids: rawLeg.route_leg_ids ?? [],
        in_vehicle_s: inVehicleS,
        wait_s: waitS,
        fare,
        supply: { kind: 'graph' },
        load_warning: input.filters.load.flagged
          ? loadWarning(mode.load_capacity, input.filters.load.size, input.plannerCfg.warnCapacities)
          : null,
      });
    }

    if (builtLegs.length !== itin.legs.length || !dominantMode) continue;

    const walkTotalM = originWalkM + destWalkM + transferWalkM;
    const walkS = originWalkS + destWalkS +
      walkSeconds(transferWalkM, input.plannerCfg.walkSpeedMps);
    const transferCount = Math.max(0, itin.legs.length - 1);

    const partial = computeMetrics({
      walkTotalM,
      walkS: walkS + transferS,
      waitS: totalWaitS,
      inVehicleS: totalInVehicleS,
      transferCount,
      totalFare: { amount: totalFareAmount.toFixed(2), currency },
      mode: dominantMode,
      cfg: input.plannerCfg,
    });
    const metrics: Metrics = {
      ...partial,
      recommended_score: 0,
      explain: { fare: 0, time: 0, strenuous: 0 },
    };

    const candidate: PlanCandidate = {
      candidate_id: crypto.randomUUID(),
      kind: 'multi_leg',
      source: 'graph',
      viable_direct: false,
      legs: builtLegs,
      transfers: itin.transfers ?? [],
      metrics,
    };

    if (isDuplicateOfDirect(candidate, input.directSignatures)) continue;
    built.push(candidate);
  }

  return { candidates: built, degraded };
}

export { directSignature };
