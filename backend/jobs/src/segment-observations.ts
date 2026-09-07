export type SegmentObservation = {
  segmentKey: string;
  speedMps: number;
  observedAt: Date;
};

export type MatchedTraceForSpeed = {
  cityId: string;
  confidence: number;
  osmWayIds: number[];
  matchMeta: Record<string, unknown>;
};

/** doc 04 §15: 0 = Mon–Fri, 1 = Sat–Sun */
export function dowBucket(date: Date, timeZone = 'UTC'): 0 | 1 {
  const weekday = new Intl.DateTimeFormat('en-US', {
    timeZone,
    weekday: 'short',
  }).format(date);
  return weekday === 'Sat' || weekday === 'Sun' ? 1 : 0;
}

export function hourBucket(date: Date, timeZone = 'UTC'): number {
  const hour = Number(
    new Intl.DateTimeFormat('en-US', {
      timeZone,
      hour: 'numeric',
      hour12: false,
    }).format(date),
  );
  return hour === 24 ? 0 : hour;
}

function parseObservation(raw: unknown): SegmentObservation | null {
  if (!raw || typeof raw !== 'object') return null;
  const row = raw as Record<string, unknown>;
  const segmentKey = row.segment_key ?? row.segmentKey;
  const speedMps = row.speed_mps ?? row.speedMps;
  const observedAt = row.observed_at ?? row.observedAt;
  if (typeof segmentKey !== 'string' || !segmentKey.includes(':')) return null;
  const speed = Number(speedMps);
  if (!Number.isFinite(speed) || speed <= 0) return null;
  const at = observedAt instanceof Date
    ? observedAt
    : new Date(String(observedAt));
  if (Number.isNaN(at.getTime())) return null;
  return { segmentKey, speedMps: speed, observedAt: at };
}

function directionForIndex(index: number): 'forward' | 'reverse' {
  return index % 2 === 0 ? 'forward' : 'reverse';
}

/**
 * Derive per-segment speeds from matched_traces columns only (FM27).
 * Prefers match_meta.segment_observations; falls back to osm_way_ids + duration/distance meta.
 */
export function extractObservationsFromMatchedTrace(
  trace: MatchedTraceForSpeed,
): SegmentObservation[] {
  const meta = trace.matchMeta ?? {};
  const direct = meta.segment_observations ?? meta.segmentObservations;
  if (Array.isArray(direct) && direct.length > 0) {
    return direct
      .map(parseObservation)
      .filter((obs): obs is SegmentObservation => obs !== null);
  }

  const durationS = Number(meta.duration_s ?? meta.durationS);
  const distanceM = Number(meta.distance_m ?? meta.distanceM);
  if (
    trace.osmWayIds.length === 0 ||
    !Number.isFinite(durationS) ||
    durationS <= 0 ||
    !Number.isFinite(distanceM) ||
    distanceM <= 0
  ) {
    return [];
  }

  const startedAtRaw = meta.started_at ?? meta.startedAt;
  const startedAt = startedAtRaw instanceof Date
    ? startedAtRaw
    : new Date(String(startedAtRaw ?? Date.now()));
  const wayCount = trace.osmWayIds.length;
  const speedMps = distanceM / durationS;
  const segmentDurationMs = (durationS * 1000) / wayCount;

  return trace.osmWayIds.map((wayId, index) => ({
    segmentKey: `${wayId}:${directionForIndex(index)}`,
    speedMps,
    observedAt: new Date(startedAt.getTime() + index * segmentDurationMs),
  }));
}

export type SpeedProfileAggregate = {
  segmentKey: string;
  cityId: string;
  dowBucket: 0 | 1;
  hourBucket: number;
  medianSpeedMps: number;
  p85SpeedMps: number;
  sampleCount: number;
};

function bucketKey(
  segmentKey: string,
  cityId: string,
  dowBucket: number,
  hourBucket: number,
): string {
  return `${cityId}|${segmentKey}|${dowBucket}|${hourBucket}`;
}

export function median(values: number[]): number {
  if (values.length === 0) return 0;
  const sorted = [...values].sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);
  if (sorted.length % 2 === 0) {
    return (sorted[mid - 1]! + sorted[mid]!) / 2;
  }
  return sorted[mid]!;
}

export function percentile(values: number[], p: number): number {
  if (values.length === 0) return 0;
  const sorted = [...values].sort((a, b) => a - b);
  const rank = (p / 100) * (sorted.length - 1);
  const lower = Math.floor(rank);
  const upper = Math.ceil(rank);
  if (lower === upper) return sorted[lower]!;
  const weight = rank - lower;
  return sorted[lower]! * (1 - weight) + sorted[upper]! * weight;
}

export function aggregateSpeedProfiles(
  observations: Array<SegmentObservation & { cityId: string }>,
  minSamples: number,
  timeZone = 'UTC',
): SpeedProfileAggregate[] {
  const groups = new Map<string, { cityId: string; segmentKey: string; dow: 0 | 1; hour: number; speeds: number[] }>();

  for (const obs of observations) {
    const dow = dowBucket(obs.observedAt, timeZone);
    const hour = hourBucket(obs.observedAt, timeZone);
    const key = bucketKey(obs.segmentKey, obs.cityId, dow, hour);
    const group = groups.get(key) ?? {
      cityId: obs.cityId,
      segmentKey: obs.segmentKey,
      dow,
      hour,
      speeds: [],
    };
    group.speeds.push(obs.speedMps);
    groups.set(key, group);
  }

  const profiles: SpeedProfileAggregate[] = [];
  for (const group of groups.values()) {
    if (group.speeds.length < minSamples) continue;
    profiles.push({
      segmentKey: group.segmentKey,
      cityId: group.cityId,
      dowBucket: group.dow,
      hourBucket: group.hour,
      medianSpeedMps: Math.round(median(group.speeds) * 100) / 100,
      p85SpeedMps: Math.round(percentile(group.speeds, 85) * 100) / 100,
      sampleCount: group.speeds.length,
    });
  }

  return profiles;
}
