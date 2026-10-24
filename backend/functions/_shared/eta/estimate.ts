/**
 * Live ETA. One payload for pickup, the trip, and each remaining stop.
 *
 * Segment speed falls through live 10-minute map-matched median (>= 4 samples),
 * then the Abuja hour profile, then the planned OSRM or graph duration.
 * Display smoothing is 70/30. A minute change publishes after a confirming
 * sample. A slowdown of more than 90 seconds publishes immediately. One fast
 * GPS spike does not pull the number down.
 */

export const ETA_THROTTLE_MS = 15_000;
export const LIVE_WINDOW_MS = 10 * 60 * 1000;
export const LIVE_MIN_SAMPLES = 4;
export const PROFILE_MIN_SAMPLES = 8;
export const DWELL_MIN_TRIPS = 8;
export const AGREE_RATIO = 0.15;
export const SLOWDOWN_S = 90;
export const EMA_PREV = 0.7;
export const EMA_NEXT = 0.3;
export const ETA_TIME_ZONE = 'Africa/Lagos';

export type SpeedSource = 'live' | 'profile' | 'planned';

export type SegmentInput = {
  key: string;
  /** Planned in-vehicle seconds from the graph or OSRM. */
  plannedS: number;
  baselineMps: number;
  liveMedianMps?: number | null;
  liveSamples?: number;
  profileMedianMps?: number | null;
  profileP85Mps?: number | null;
  profileSamples?: number;
  osrmDegraded?: boolean;
};

export type SegmentEstimate = {
  lowS: number;
  highS: number;
  kind: 'single' | 'range';
  source: SpeedSource;
};

export type StopInput = {
  id: string;
  name: string;
  passed?: boolean;
  current?: boolean;
  actualArrival?: Date | null;
  /** Seconds of riding from the previous point to this stop. */
  approach?: SegmentInput | null;
  dwellObservedS?: number | null;
  dwellSamples?: number;
  dwellDefaultS?: number;
};

export type SmoothState = {
  emaS: number;
  rawS: number;
  publishedLowS: number;
  publishedHighS: number;
  pendingLowS: number | null;
  pendingHighS: number | null;
  spikeRejected: boolean;
  liveSpeedMps: number | null;
};

export type EtaValue = {
  kind: 'single' | 'range';
  lowS: number;
  highS: number;
  label: string;
};

export type EtaStop = {
  id: string;
  name: string;
  state: 'passed' | 'current' | 'upcoming';
  label: string;
};

export type EtaPayload = {
  status: 'calculating' | 'ready';
  pickup: EtaValue | null;
  trip: EtaValue | null;
  stops: EtaStop[];
  updatedAt: string;
};

export type EstimateInput = {
  now: Date;
  pickup?: SegmentInput | null;
  walkS?: number | null;
  stops: StopInput[];
  previous?: SmoothState | null;
};

export type EstimateResult = {
  payload: EtaPayload;
  state: SmoothState | null;
};

export type SegmentObservation = {
  segmentKey: string;
  speedMps: number;
  at: Date;
};

export function dueForRefresh(
  lastAt: Date | null,
  now: Date,
  throttleMs = ETA_THROTTLE_MS,
): boolean {
  if (lastAt == null) return true;
  return now.getTime() - lastAt.getTime() >= throttleMs;
}

/** Median speed on one segment over the last 10 minutes. Null under 4 samples. */
export function liveSegmentMedian(
  observations: SegmentObservation[],
  segmentKey: string,
  now: Date,
  windowMs = LIVE_WINDOW_MS,
): { medianMps: number; samples: number } | null {
  const cutoff = now.getTime() - windowMs;
  const speeds = observations
    .filter((row) =>
      row.segmentKey === segmentKey &&
      row.at.getTime() >= cutoff &&
      Number.isFinite(row.speedMps) &&
      row.speedMps > 0
    )
    .map((row) => row.speedMps)
    .sort((a, b) => a - b);
  if (speeds.length < LIVE_MIN_SAMPLES) return null;
  const mid = Math.floor(speeds.length / 2);
  const median = speeds.length % 2 === 1
    ? speeds[mid]!
    : (speeds[mid - 1]! + speeds[mid]!) / 2;
  return { medianMps: median, samples: speeds.length };
}

export function dwellSeconds(
  observedS: number | null | undefined,
  samples: number | undefined,
  modeDefaultS: number,
): number {
  if (
    observedS != null &&
    Number.isFinite(observedS) &&
    observedS >= 0 &&
    (samples ?? 0) >= DWELL_MIN_TRIPS
  ) {
    return Math.round(observedS);
  }
  return Math.max(0, Math.round(modeDefaultS));
}

function scaled(plannedS: number, baselineMps: number, speedMps: number): number {
  if (plannedS <= 0 || baselineMps <= 0 || speedMps <= 0) return Math.max(1, plannedS);
  return Math.max(1, Math.round(plannedS * (baselineMps / speedMps)));
}

/** Blend one segment. Live median, then the hour profile, then the plan. */
export function blendSegment(segment: SegmentInput): SegmentEstimate {
  const planned = Math.max(1, Math.round(segment.plannedS));
  const liveOk = (segment.liveSamples ?? 0) >= LIVE_MIN_SAMPLES &&
    (segment.liveMedianMps ?? 0) > 0;
  const profileOk = (segment.profileSamples ?? 0) >= PROFILE_MIN_SAMPLES &&
    (segment.profileMedianMps ?? 0) > 0;
  const p85 = segment.profileP85Mps ?? 0;

  let source: SpeedSource = 'planned';
  let chosen = planned;
  if (liveOk) {
    source = 'live';
    chosen = scaled(planned, segment.baselineMps, segment.liveMedianMps!);
  } else if (profileOk) {
    source = 'profile';
    chosen = scaled(planned, segment.baselineMps, segment.profileMedianMps!);
  }

  let low = chosen;
  let high = chosen;
  let kind: 'single' | 'range' = 'single';

  const profileSpeed = segment.profileMedianMps ?? 0;
  const liveSpeed = segment.liveMedianMps ?? 0;
  const agree = liveOk && profileOk && profileSpeed > 0 &&
    Math.abs(liveSpeed - profileSpeed) / profileSpeed <= AGREE_RATIO;

  if (!agree && p85 > 0 && (profileOk || liveOk)) {
    const slowEdge = scaled(planned, segment.baselineMps, p85);
    low = Math.min(chosen, slowEdge);
    high = Math.max(chosen, slowEdge);
    kind = low === high ? 'single' : 'range';
  }

  if (segment.osrmDegraded) {
    const mid = (low + high) / 2;
    const pad = Math.max(120, Math.round(mid * 0.25));
    low = Math.max(1, low - pad);
    high = high + pad;
    kind = 'range';
  }

  return { lowS: low, highS: high, kind, source };
}

export function sumSegments(segments: SegmentInput[]): SegmentEstimate {
  if (segments.length === 0) {
    return { lowS: 0, highS: 0, kind: 'single', source: 'planned' };
  }
  const parts = segments.map(blendSegment);
  const low = parts.reduce((sum, part) => sum + part.lowS, 0);
  const high = parts.reduce((sum, part) => sum + part.highS, 0);
  const source = parts.some((part) => part.source === 'live')
    ? 'live'
    : parts.some((part) => part.source === 'profile')
    ? 'profile'
    : 'planned';
  const degraded = segments.some((segment) => segment.osrmDegraded);
  return {
    lowS: low,
    highS: high,
    kind: degraded || low !== high ? 'range' : 'single',
    source,
  };
}

function minuteOf(seconds: number): number {
  return Math.max(0, Math.round(seconds / 60));
}

function representativeSpeed(segments: SegmentInput[]): number | null {
  const live = segments.find((segment) =>
    (segment.liveSamples ?? 0) >= LIVE_MIN_SAMPLES && (segment.liveMedianMps ?? 0) > 0
  );
  return live?.liveMedianMps ?? null;
}

/**
 * EMA 70/30. Publish when a new minute is confirmed by the next sample.
 * Surface a slowdown above 90 seconds on this sample. Reject one fast spike.
 */
export function smoothEta(input: {
  rawLowS: number;
  rawHighS: number;
  segments: SegmentInput[];
  previous: SmoothState | null;
}): { state: SmoothState; lowS: number; highS: number } {
  const liveSpeed = representativeSpeed(input.segments);
  let rawLow = input.rawLowS;
  let rawHigh = input.rawHighS;
  let spikeRejected = false;
  const previous = input.previous;

  if (previous && liveSpeed != null && previous.liveSpeedMps != null) {
    const spiked = liveSpeed > previous.liveSpeedMps * 2 && rawLow < previous.rawS * 0.75;
    if (spiked && !previous.spikeRejected) {
      rawLow = previous.rawS;
      rawHigh = Math.max(rawLow, previous.publishedHighS);
      spikeRejected = true;
    }
  }

  const ema = previous == null
    ? rawLow
    : Math.round(EMA_PREV * previous.emaS + EMA_NEXT * rawLow);

  if (
    previous &&
    (rawLow >= previous.publishedLowS + SLOWDOWN_S ||
      rawHigh >= previous.publishedHighS + SLOWDOWN_S)
  ) {
    const state: SmoothState = {
      emaS: rawLow,
      rawS: rawLow,
      publishedLowS: rawLow,
      publishedHighS: Math.max(rawLow, rawHigh),
      pendingLowS: null,
      pendingHighS: null,
      spikeRejected: false,
      liveSpeedMps: liveSpeed,
    };
    return { state, lowS: state.publishedLowS, highS: state.publishedHighS };
  }

  const nextLow = ema;
  const span = Math.max(0, rawHigh - rawLow);
  const nextHigh = nextLow + span;
  if (previous == null) {
    const state: SmoothState = {
      emaS: nextLow,
      rawS: rawLow,
      publishedLowS: nextLow,
      publishedHighS: nextHigh,
      pendingLowS: null,
      pendingHighS: null,
      spikeRejected,
      liveSpeedMps: liveSpeed,
    };
    return { state, lowS: nextLow, highS: nextHigh };
  }

  const sameMinute = minuteOf(nextLow) === minuteOf(previous.publishedLowS) &&
    minuteOf(nextHigh) === minuteOf(previous.publishedHighS);
  if (sameMinute) {
    const state: SmoothState = {
      emaS: nextLow,
      rawS: rawLow,
      publishedLowS: previous.publishedLowS,
      publishedHighS: previous.publishedHighS,
      pendingLowS: null,
      pendingHighS: null,
      spikeRejected,
      liveSpeedMps: liveSpeed,
    };
    return { state, lowS: state.publishedLowS, highS: state.publishedHighS };
  }

  const confirms = previous.pendingLowS != null &&
    minuteOf(previous.pendingLowS) === minuteOf(nextLow) &&
    minuteOf(previous.pendingHighS ?? previous.pendingLowS) === minuteOf(nextHigh);
  if (confirms) {
    const state: SmoothState = {
      emaS: nextLow,
      rawS: rawLow,
      publishedLowS: nextLow,
      publishedHighS: nextHigh,
      pendingLowS: null,
      pendingHighS: null,
      spikeRejected,
      liveSpeedMps: liveSpeed,
    };
    return { state, lowS: nextLow, highS: nextHigh };
  }

  const state: SmoothState = {
    emaS: nextLow,
    rawS: rawLow,
    publishedLowS: previous.publishedLowS,
    publishedHighS: previous.publishedHighS,
    pendingLowS: nextLow,
    pendingHighS: nextHigh,
    spikeRejected,
    liveSpeedMps: liveSpeed,
  };
  return { state, lowS: state.publishedLowS, highS: state.publishedHighS };
}

export function formatEta(lowS: number, highS: number): EtaValue {
  const low = minuteOf(lowS);
  const high = minuteOf(highS);
  if (low === high) {
    return { kind: 'single', lowS, highS: lowS, label: `${low} min` };
  }
  const start = Math.min(low, high);
  const end = Math.max(low, high);
  return {
    kind: 'range',
    lowS: Math.min(lowS, highS),
    highS: Math.max(lowS, highS),
    label: `${start}–${end} min`,
  };
}

export function lagosClock(at: Date, timeZone = ETA_TIME_ZONE): string {
  const parts = new Intl.DateTimeFormat('en-GB', {
    timeZone,
    hour: 'numeric',
    minute: '2-digit',
    hourCycle: 'h23',
  }).formatToParts(at);
  const hour = parts.find((part) => part.type === 'hour')?.value ?? '0';
  const minute = parts.find((part) => part.type === 'minute')?.value ?? '00';
  return `${Number(hour)}:${minute}`;
}

export function stopClocks(
  stops: StopInput[],
  now: Date,
  timeZone = ETA_TIME_ZONE,
): EtaStop[] {
  let cursor = 0;
  return stops.map((stop) => {
    const approach = stop.approach ? blendSegment(stop.approach).lowS : 0;
    const dwell = stop.passed || stop.current
      ? 0
      : dwellSeconds(stop.dwellObservedS, stop.dwellSamples, stop.dwellDefaultS ?? 0);
    if (!stop.passed && !stop.current) cursor += approach;
    const state = stop.passed ? 'passed' : stop.current ? 'current' : 'upcoming';
    let label = 'Calculating…';
    if (stop.passed) {
      label = stop.actualArrival ? lagosClock(stop.actualArrival, timeZone) : 'Passed';
    } else if (stop.current) {
      label = 'Now';
    } else {
      label = lagosClock(new Date(now.getTime() + cursor * 1000), timeZone);
      cursor += dwell;
    }
    return { id: stop.id, name: stop.name, state, label };
  });
}

export function estimateTrip(input: EstimateInput): EstimateResult {
  const lastIndex = input.stops.length - 1;
  const upcoming = input.stops.filter((stop) => !stop.passed && !stop.current);
  const rideSegments = upcoming
    .map((stop) => stop.approach)
    .filter((segment): segment is SegmentInput => segment != null);
  // Dwell is time at an intermediate stop. The last stop is the arrival.
  const dwell = input.stops.reduce((sum, stop, index) => {
    if (index === lastIndex || stop.passed || stop.current) return sum;
    return sum + dwellSeconds(stop.dwellObservedS, stop.dwellSamples, stop.dwellDefaultS ?? 0);
  }, 0);

  const known = input.stops.some((stop) => stop.passed || stop.current);
  if (rideSegments.length === 0 && input.pickup == null && !known) {
    return {
      payload: {
        status: 'calculating',
        pickup: null,
        trip: null,
        stops: input.stops.map((stop) => ({
          id: stop.id,
          name: stop.name,
          state: stop.passed ? 'passed' : stop.current ? 'current' : 'upcoming',
          label: stop.passed && stop.actualArrival
            ? lagosClock(stop.actualArrival)
            : 'Calculating…',
        })),
        updatedAt: input.now.toISOString(),
      },
      state: input.previous ?? null,
    };
  }

  let trip: EtaValue | null = null;
  let state = input.previous ?? null;
  if (rideSegments.length > 0) {
    const ride = sumSegments(rideSegments);
    const smoothed = smoothEta({
      rawLowS: ride.lowS + dwell,
      rawHighS: ride.highS + dwell,
      segments: rideSegments,
      previous: input.previous ?? null,
    });
    trip = formatEta(smoothed.lowS, smoothed.highS);
    state = smoothed.state;
  }

  let pickup: EtaValue | null = null;
  if (input.pickup) {
    const blended = blendSegment(input.pickup);
    const walk = Math.max(0, input.walkS ?? 0);
    pickup = formatEta(blended.lowS + walk, blended.highS + walk);
  }

  return {
    payload: {
      status: 'ready',
      pickup,
      trip,
      stops: stopClocks(input.stops, input.now),
      updatedAt: input.now.toISOString(),
    },
    state,
  };
}
