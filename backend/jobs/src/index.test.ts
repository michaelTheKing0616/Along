import { describe, expect, it, vi } from 'vitest';

import { runMapMatchJob, type JobsDb } from './map-match.js';
import { proposeFromTraces } from './propose-from-traces.js';
import { JOBS_VERSION } from './index.js';
import type { MatchedTraceRecord, TraceSample } from './types.js';

function sampleTrace(count: number): TraceSample[] {
  return Array.from({ length: count }, (_, i) => ({
    lng: 7.4 + i * 0.001,
    lat: 9.0 + i * 0.001,
    ts: new Date(`2026-01-01T10:0${i % 10}:00Z`),
    accuracyM: 20,
  }));
}

function mockDb(overrides: Partial<JobsDb> = {}): JobsDb {
  return {
    beginJobRun: vi.fn(async () => ({
      id: 'job-1',
      jobName: 'map-match',
      status: 'running' as const,
    })),
    finishJobRun: vi.fn(async () => undefined),
    loadMapMatchConfig: vi.fn(async () => ({
      minSamples: 10,
      minConfidence: 0.6,
      osrmBaseUrl: 'http://osrm.test',
      osrmTimeoutMs: 8000,
      defaultRadiusM: 25,
    })),
    listPendingTraceMatches: vi.fn(async () => []),
    loadTraceSamples: vi.fn(async () => []),
    insertMatchedTrace: vi.fn(async () => true),
    ...overrides,
  };
}

describe('jobs bootstrap', () => {
  it('exports version', () => {
    expect(JOBS_VERSION).toBe('0.1.0');
  });
});

describe('FM27 propose_from_traces', () => {
  it('returns zero proposals when only raw unmatched traces are supplied', () => {
    const proposals = proposeFromTraces({
      traces: [{
        tripId: 'trip-raw',
        actorType: 'driver',
        samples: sampleTrace(12),
      }],
      matchedByTripActor: new Map<string, MatchedTraceRecord>(),
      minConfidence: 0.6,
    });

    expect(proposals).toEqual([]);
  });

  it('returns zero proposals when matched confidence is below cfg', () => {
    const matched: MatchedTraceRecord = {
      tripId: 'trip-low',
      actorType: 'driver',
      confidence: 0.45,
      geometryGeoJson: { type: 'LineString', coordinates: [[7.4, 9.0], [7.41, 9.01]] },
      osmWayIds: [],
      matchMeta: {},
    };

    const proposals = proposeFromTraces({
      traces: [{
        tripId: 'trip-low',
        actorType: 'driver',
        samples: sampleTrace(12),
      }],
      matchedByTripActor: new Map([['trip-low:driver', matched]]),
      minConfidence: 0.6,
    });

    expect(proposals).toEqual([]);
  });
});

describe('map-match confidence filter', () => {
  it('does not insert matched_traces when OSRM confidence is below cfg', async () => {
    const insertMatchedTrace = vi.fn(async () => true);
    const db = mockDb({
      listPendingTraceMatches: vi.fn(async () => [{
        tripId: 'trip-1',
        cityId: 'city-1',
        actorType: 'driver' as const,
        sampleCount: 12,
      }]),
      loadTraceSamples: vi.fn(async () => sampleTrace(12)),
      insertMatchedTrace,
    });

    const stats = await runMapMatchJob({
      db,
      osrm: {
        carMatch: vi.fn(async () => ({
          confidence: 0.45,
          geometry: {
            type: 'LineString' as const,
            coordinates: [[7.4, 9.0], [7.41, 9.01]] as [number, number][],
          },
          osmWayIds: [],
          matchMeta: { code: 'Ok' },
          degraded: false,
        })),
      },
    });

    expect(insertMatchedTrace).not.toHaveBeenCalled();
    expect(stats.skipped_low_confidence).toBe(1);
    expect(stats.matched).toBe(0);
  });

  it('inserts matched_traces when OSRM confidence meets cfg', async () => {
    const insertMatchedTrace = vi.fn(async () => true);
    const db = mockDb({
      listPendingTraceMatches: vi.fn(async () => [{
        tripId: 'trip-2',
        cityId: 'city-1',
        actorType: 'rider' as const,
        sampleCount: 10,
      }]),
      loadTraceSamples: vi.fn(async () => sampleTrace(10)),
      insertMatchedTrace,
    });

    const stats = await runMapMatchJob({
      db,
      osrm: {
        carMatch: vi.fn(async () => ({
          confidence: 0.82,
          geometry: {
            type: 'LineString' as const,
            coordinates: [[7.4, 9.0], [7.41, 9.01], [7.42, 9.02]] as [number, number][],
          },
          osmWayIds: [],
          matchMeta: { code: 'Ok' },
          degraded: false,
        })),
      },
    });

    expect(insertMatchedTrace).toHaveBeenCalledOnce();
    expect(stats.matched).toBe(1);
  });
});
