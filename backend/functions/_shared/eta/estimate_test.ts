import { assert, assertEquals } from 'jsr:@std/assert@1';
import {
  blendSegment,
  dwellSeconds,
  estimateTrip,
  formatEta,
  lagosClock,
  liveSegmentMedian,
  smoothEta,
  type SegmentInput,
  type SmoothState,
} from './estimate.ts';

const NOW = new Date('2026-10-24T06:30:00.000Z');

function segment(overrides: Partial<SegmentInput> = {}): SegmentInput {
  return {
    key: 'wuse:north',
    plannedS: 300,
    baselineMps: 10,
    ...overrides,
  };
}

function state(overrides: Partial<SmoothState> = {}): SmoothState {
  return {
    emaS: 500,
    rawS: 500,
    publishedLowS: 500,
    publishedHighS: 500,
    pendingLowS: null,
    pendingHighS: null,
    spikeRejected: false,
    liveSpeedMps: 6,
    ...overrides,
  };
}

Deno.test('blend uses live median, then the hour profile, then the plan', () => {
  const live = blendSegment(segment({
    liveMedianMps: 6,
    liveSamples: 4,
    profileMedianMps: 6,
    profileP85Mps: 9,
    profileSamples: 8,
  }));
  assertEquals(live.source, 'live');
  assertEquals(live.lowS, 500);
  assertEquals(live.kind, 'single');

  const thinLive = blendSegment(segment({
    liveMedianMps: 6,
    liveSamples: 3,
    profileMedianMps: 5,
    profileSamples: 8,
  }));
  assertEquals(thinLive.source, 'profile');
  assertEquals(thinLive.lowS, 600);
  assertEquals(thinLive.kind, 'single');

  const thinProfile = blendSegment(segment({
    liveSamples: 2,
    profileMedianMps: 5,
    profileSamples: 7,
  }));
  assertEquals(thinProfile.source, 'planned');
  assertEquals(thinProfile.lowS, 300);
  assertEquals(thinProfile.kind, 'single');
});

Deno.test('range is p85 to the chosen time, and a single value when speeds agree', () => {
  const agreed = blendSegment(segment({
    liveMedianMps: 6,
    liveSamples: 4,
    profileMedianMps: 6.2,
    profileP85Mps: 9,
    profileSamples: 8,
  }));
  assertEquals(agreed.kind, 'single');
  assertEquals(agreed.lowS, 500);
  assertEquals(formatEta(agreed.lowS, agreed.highS).label, '8 min');

  const split = blendSegment(segment({
    liveMedianMps: 6,
    liveSamples: 4,
    profileMedianMps: 10,
    profileP85Mps: 9,
    profileSamples: 8,
  }));
  assertEquals(split.kind, 'range');
  assertEquals(split.lowS, 333);
  assertEquals(split.highS, 500);
  assertEquals(formatEta(split.lowS, split.highS).label, '6–8 min');

  const widened = blendSegment(segment({ plannedS: 800, osrmDegraded: true }));
  assertEquals(widened.kind, 'range');
  assertEquals(widened.source, 'planned');
  assertEquals(widened.lowS, 600);
  assertEquals(widened.highS, 1000);
  assertEquals(formatEta(widened.lowS, widened.highS).label, '10–17 min');
});

Deno.test('dwell uses the observed stage value only after 8 trips', () => {
  assertEquals(dwellSeconds(45, 7, 120), 120);
  assertEquals(dwellSeconds(45, 8, 120), 45);
  assertEquals(dwellSeconds(null, 12, 90), 90);
  assertEquals(dwellSeconds(-5, 9, 90), 90);
});

Deno.test('smoothing is 70/30, confirms a minute, surfaces a jam, and drops one spike', () => {
  const first = smoothEta({
    rawLowS: 500,
    rawHighS: 500,
    segments: [segment({ liveMedianMps: 6, liveSamples: 4 })],
    previous: null,
  });
  assertEquals(first.lowS, 500);

  const held = smoothEta({
    rawLowS: 400,
    rawHighS: 400,
    segments: [segment({ liveMedianMps: 6, liveSamples: 4 })],
    previous: state({ emaS: 500, publishedLowS: 500, publishedHighS: 500 }),
  });
  assertEquals(held.state.emaS, 470);
  assertEquals(held.lowS, 500);

  const pending = smoothEta({
    rawLowS: 480,
    rawHighS: 480,
    segments: [segment({ liveMedianMps: 6, liveSamples: 4 })],
    previous: state({
      emaS: 600,
      rawS: 600,
      publishedLowS: 600,
      publishedHighS: 600,
    }),
  });
  assertEquals(pending.state.emaS, 564);
  assertEquals(pending.state.pendingLowS, 564);
  assertEquals(pending.lowS, 600);

  const confirmed = smoothEta({
    rawLowS: 480,
    rawHighS: 480,
    segments: [segment({ liveMedianMps: 6, liveSamples: 4 })],
    previous: pending.state,
  });
  assertEquals(confirmed.state.emaS, 539);
  assertEquals(confirmed.lowS, 539);
  assertEquals(confirmed.state.pendingLowS, null);

  const jam = smoothEta({
    rawLowS: 400,
    rawHighS: 400,
    segments: [segment({ liveMedianMps: 2, liveSamples: 4 })],
    previous: state({
      emaS: 300,
      rawS: 300,
      publishedLowS: 300,
      publishedHighS: 300,
      liveSpeedMps: 8,
    }),
  });
  assertEquals(jam.lowS, 400);
  assertEquals(jam.state.pendingLowS, null);

  const spiked = smoothEta({
    rawLowS: 100,
    rawHighS: 100,
    segments: [segment({ liveMedianMps: 30, liveSamples: 4 })],
    previous: state(),
  });
  assertEquals(spiked.state.spikeRejected, true);
  assertEquals(spiked.state.rawS, 500);
  assertEquals(spiked.lowS, 500);

  const accepted = smoothEta({
    rawLowS: 100,
    rawHighS: 100,
    segments: [segment({ liveMedianMps: 30, liveSamples: 4 })],
    previous: spiked.state,
  });
  assertEquals(accepted.state.spikeRejected, false);
  assertEquals(accepted.state.rawS, 100);
  assertEquals(accepted.lowS, 500);
});

Deno.test('live segment median keeps the last 10 minutes and needs 4 samples', () => {
  const observations = [
    { segmentKey: 'wuse:north', speedMps: 4, at: new Date(NOW.getTime() - 9 * 60_000) },
    { segmentKey: 'wuse:north', speedMps: 8, at: new Date(NOW.getTime() - 6 * 60_000) },
    { segmentKey: 'wuse:north', speedMps: 10, at: new Date(NOW.getTime() - 4 * 60_000) },
    { segmentKey: 'other', speedMps: 1, at: new Date(NOW.getTime() - 60_000) },
    { segmentKey: 'wuse:north', speedMps: 30, at: new Date(NOW.getTime() - 11 * 60_000) },
  ];
  assertEquals(liveSegmentMedian(observations, 'wuse:north', NOW), null);

  observations.push({
    segmentKey: 'wuse:north',
    speedMps: 12,
    at: new Date(NOW.getTime() - 30_000),
  });
  assertEquals(liveSegmentMedian(observations, 'wuse:north', NOW), {
    medianMps: 9,
    samples: 4,
  });

  observations.push({
    segmentKey: 'wuse:north',
    speedMps: 30,
    at: new Date(NOW.getTime() - 10_000),
  });
  assertEquals(
    liveSegmentMedian(observations, 'wuse:north', NOW)?.medianMps,
    10,
  );
});

Deno.test('a simulated Abuja trace keeps clocks, rejects one GPS spike, and publishes a jam', () => {
  const speeds = [6, 6, 6, 6, 6.4];
  const observations = speeds.map((speedMps, index) => ({
    segmentKey: 'wuse:north',
    speedMps,
    at: new Date(NOW.getTime() - (index + 1) * 60_000),
  }));
  const live = liveSegmentMedian(observations, 'wuse:north', NOW);
  assertEquals(live?.samples, 5);
  assert(live != null && live.medianMps < 7);

  const approach = segment({
    liveMedianMps: live?.medianMps,
    liveSamples: live?.samples,
    profileMedianMps: 6,
    profileP85Mps: 9,
    profileSamples: 8,
  });
  const steady = estimateTrip({
    now: NOW,
    pickup: approach,
    stops: [
      {
        id: 'wuse',
        name: 'Wuse',
        passed: true,
        actualArrival: new Date('2026-10-24T06:12:00.000Z'),
      },
      {
        id: 'berger',
        name: 'Berger',
        current: true,
      },
      {
        id: 'jabi',
        name: 'Jabi',
        approach,
        dwellObservedS: 40,
        dwellSamples: 3,
        dwellDefaultS: 120,
      },
      {
        id: 'garki',
        name: 'Garki',
        approach: segment({
          key: 'garki:east',
          plannedS: 180,
          liveMedianMps: live?.medianMps,
          liveSamples: live?.samples,
          profileMedianMps: 6,
          profileP85Mps: 9,
          profileSamples: 8,
        }),
        dwellObservedS: 40,
        dwellSamples: 8,
        dwellDefaultS: 120,
      },
    ],
  });

  assertEquals(steady.payload.status, 'ready');
  assertEquals(steady.payload.trip?.kind, 'single');
  assertEquals(steady.payload.stops[0]?.label, '7:12');
  assertEquals(steady.payload.stops[1]?.label, 'Now');
  assertEquals(lagosClock(NOW), '7:30');
  assertEquals(steady.payload.stops[2]?.label, '7:38');
  assertEquals(steady.payload.stops[3]?.label, '7:45');
  assert(steady.payload.trip != null);
  const steadyLabel = steady.payload.trip.label;

  const spikedMedian = 30;
  const spiked = estimateTrip({
    now: new Date(NOW.getTime() + 20_000),
    stops: [
      {
        id: 'garki',
        name: 'Garki',
        approach: segment({
          liveMedianMps: spikedMedian,
          liveSamples: 4,
          profileMedianMps: 6,
          profileP85Mps: 9,
          profileSamples: 8,
        }),
      },
    ],
    previous: steady.state,
  });
  assertEquals(spiked.state?.spikeRejected, true);
  assertEquals(spiked.payload.trip?.label, steadyLabel);

  const confirmedFast = estimateTrip({
    now: new Date(NOW.getTime() + 40_000),
    stops: [
      {
        id: 'garki',
        name: 'Garki',
        approach: segment({
          liveMedianMps: spikedMedian,
          liveSamples: 4,
          profileMedianMps: 6,
          profileP85Mps: 9,
          profileSamples: 8,
        }),
      },
    ],
    previous: spiked.state,
  });
  assertEquals(confirmedFast.state?.spikeRejected, false);
  assertEquals(confirmedFast.state?.rawS, 100);
  assertEquals(confirmedFast.payload.trip?.label, steadyLabel);

  const jam = estimateTrip({
    now: new Date(NOW.getTime() + 60_000),
    stops: [
      {
        id: 'garki',
        name: 'Garki',
        approach: segment({
          liveMedianMps: 1.2,
          liveSamples: 6,
          profileMedianMps: 6,
          profileP85Mps: 9,
          profileSamples: 8,
        }),
      },
    ],
    previous: steady.state,
  });
  assert(jam.state != null && steady.state != null);
  assert(jam.state.publishedHighS >= steady.state.publishedHighS + 90);
  assertEquals(jam.state.pendingLowS, null);
  assertEquals(jam.payload.trip?.label, '6–42 min');
  assertEquals(jam.payload.stops[0]?.state, 'upcoming');
});
