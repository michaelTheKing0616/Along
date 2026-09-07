import { describe, expect, it } from 'vitest';

import { runEtaAbReport } from './eta-ab.js';
import {
  aggregateSpeedProfiles,
  extractObservationsFromMatchedTrace,
  median,
} from './segment-observations.js';

const cfg = {
  baselineSpeedMps: 10,
  speedProfileMinSamples: 8,
};

describe('segment observation extraction (FM27)', () => {
  it('reads segment_observations from match_meta only', () => {
    const obs = extractObservationsFromMatchedTrace({
      cityId: 'city-1',
      confidence: 0.9,
      osmWayIds: [],
      matchMeta: {
        segment_observations: [
          {
            segment_key: '12345:forward',
            speed_mps: 5,
            observed_at: '2026-09-08T10:15:00Z',
          },
        ],
      },
    });

    expect(obs).toHaveLength(1);
    expect(obs[0]?.segmentKey).toBe('12345:forward');
    expect(obs[0]?.speedMps).toBe(5);
  });

  it('falls back to osm_way_ids + duration meta without raw GPS', () => {
    const obs = extractObservationsFromMatchedTrace({
      cityId: 'city-1',
      confidence: 0.85,
      osmWayIds: [1001, 1002],
      matchMeta: {
        duration_s: 100,
        distance_m: 500,
        started_at: '2026-09-08T10:00:00Z',
      },
    });

    expect(obs).toHaveLength(2);
    expect(obs[0]?.segmentKey).toBe('1001:forward');
    expect(obs[0]?.speedMps).toBe(5);
  });
});

describe('speed profile aggregation', () => {
  it('requires min samples before emitting a profile bucket', () => {
    const observations = Array.from({ length: 7 }, (_, i) => ({
      cityId: 'city-1',
      segmentKey: '999:forward',
      speedMps: 5 + i * 0.1,
      observedAt: new Date(`2026-09-08T10:${String(i).padStart(2, '0')}:00Z`),
    }));

    expect(aggregateSpeedProfiles(observations, 8)).toEqual([]);
    expect(aggregateSpeedProfiles([...observations, {
      cityId: 'city-1',
      segmentKey: '999:forward',
      speedMps: 6,
      observedAt: new Date('2026-09-08T10:08:00Z'),
    }], 8)).toHaveLength(1);
  });

  it('computes median speed per segment × dow × hour', () => {
    const observations = Array.from({ length: 8 }, () => ({
      cityId: 'city-1',
      segmentKey: '777:forward',
      speedMps: 4,
      observedAt: new Date('2026-09-08T10:30:00Z'),
    }));

    const profiles = aggregateSpeedProfiles(observations, 8, 'UTC');
    expect(profiles[0]).toMatchObject({
      segmentKey: '777:forward',
      dowBucket: 0,
      hourBucket: 10,
      medianSpeedMps: 4,
      sampleCount: 8,
    });
  });
});

describe('P7-A-03 ETA A/B report fixture', () => {
  it('profiles reduce MAE vs generic baseline on matched-trace fixture', () => {
    const legs = [
      {
        segmentKeys: ['501:forward'],
        baseInVehicleS: 600,
        actualDurationS: 1200,
        profileMedianSpeedMps: 5,
      },
      {
        segmentKeys: ['502:forward'],
        baseInVehicleS: 900,
        actualDurationS: 1800,
        profileMedianSpeedMps: 5,
      },
      {
        segmentKeys: ['503:forward'],
        baseInVehicleS: 450,
        actualDurationS: 900,
        profileMedianSpeedMps: 5,
      },
    ];

    const report = runEtaAbReport(legs, cfg);

    expect(report.maeBaselineS).toBe(650);
    expect(report.maeProfileS).toBe(0);
    expect(report.improvementPct).toBe(100);
    expect(report.maeProfileS).toBeLessThan(report.maeBaselineS);
  });

  it('median helper matches expected value', () => {
    expect(median([4, 5, 6, 7, 8])).toBe(6);
  });
});
