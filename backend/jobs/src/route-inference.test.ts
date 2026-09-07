import { describe, expect, it, vi } from 'vitest';

import {
  clusterGeometryCorrections,
  extractLowConfidenceSegments,
  runGeometryCorrectionsJob,
} from './geometry-corrections.js';
import {
  clusterTracesForRouteInference,
  runRouteInferenceJob,
  type MatchedTraceForInference,
} from './route-inference.js';
import { discreteFrechetM } from './frechet.js';

function corridorTrace(
  tripId: string,
  offset: number,
): MatchedTraceForInference {
  const origin: [number, number] = [7.82, 11.12];
  const destination: [number, number] = [7.836, 11.128];
  const coordinates: [number, number][] = [
    origin,
    ...Array.from({ length: 6 }, (_, i) => [
      7.822 + i * 0.002 + offset * 0.00001,
      11.121 + i * 0.001 + offset * 0.00001,
    ] as [number, number]),
    destination,
  ];

  return {
    tripId,
    cityId: 'city-undeclared',
    modeCode: 'car',
    confidence: 0.85,
    geometryGeoJson: { type: 'LineString', coordinates },
    matchMeta: {},
  };
}

describe('route inference job', () => {
  it('produces a route_inference candidate for simulated undeclared corridor (≥20 trips)', async () => {
    const traces = Array.from({ length: 22 }, (_, i) => corridorTrace(`trip-${i}`, i));
    const candidates = clusterTracesForRouteInference(traces, {
      minTrips: 20,
      frechetM: 150,
      minConfidence: 0.6,
    });

    expect(candidates.length).toBeGreaterThanOrEqual(1);
    expect(candidates[0]?.supportingTripCount).toBeGreaterThanOrEqual(20);
    expect(candidates[0]?.modeCode).toBe('car');
  });

  it('runRouteInferenceJob inserts candidates without writing routes', async () => {
    const traces = Array.from({ length: 20 }, (_, i) => corridorTrace(`trip-${i}`, i));
    const insertRouteInferenceCandidates = vi.fn(async () => 1);
    const stats = await runRouteInferenceJob({
      beginJobRun: vi.fn(async () => ({
        id: 'job-ri-1',
        jobName: 'route-inference',
        status: 'running' as const,
      })),
      finishJobRun: vi.fn(async () => undefined),
      loadRouteInferenceConfig: vi.fn(async () => ({
        minTrips: 20,
        frechetM: 150,
        minConfidence: 0.6,
      })),
      listMatchedTracesForInference: vi.fn(async () => traces),
      insertRouteInferenceCandidates,
    });

    expect(stats.candidates_inserted).toBe(1);
    expect(insertRouteInferenceCandidates).toHaveBeenCalledOnce();
    expect(stats.groups_found).toBe(1);
  });

  it('withholds divergent traces from the candidate group', () => {
    const similar = corridorTrace('trip-a', 0);
    const divergent: MatchedTraceForInference = {
      ...corridorTrace('trip-b', 0),
      geometryGeoJson: {
        type: 'LineString',
        coordinates: [
          [7.82, 11.12],
          [8.5, 11.5],
          [8.7, 11.7],
          [7.836, 11.128],
        ],
      },
    };
    const traces = [
      ...Array.from({ length: 19 }, (_, i) => corridorTrace(`trip-${i}`, i)),
      similar,
      divergent,
    ];

    const candidates = clusterTracesForRouteInference(traces, {
      minTrips: 20,
      frechetM: 150,
      minConfidence: 0.6,
    });

    expect(candidates.length).toBe(1);
    expect(candidates[0]?.supportingTripCount).toBe(20);
    expect(
      discreteFrechetM(
        similar.geometryGeoJson.coordinates,
        divergent.geometryGeoJson.coordinates,
      ),
    ).toBeGreaterThan(150);
  });
});

describe('geometry corrections job', () => {
  it('clusters low-confidence segments into correction candidates', () => {
    const traces = Array.from({ length: 16 }, (_, i) => ({
      tripId: `trip-${i}`,
      cityId: 'city-1',
      confidence: 0.9,
      matchMeta: {
        low_confidence_segments: [{
          lng: 7.401 + (i % 3) * 0.00001,
          lat: 9.001 + (i % 3) * 0.00001,
          confidence: 0.35,
        }],
      },
    }));

    const segments = extractLowConfidenceSegments(traces, 0.6);
    expect(segments.length).toBe(16);

    const corrections = clusterGeometryCorrections(segments, {
      minSupportingTraces: 15,
      clusterM: 20,
      minConfidence: 0.6,
    });

    expect(corrections.length).toBe(1);
    expect(corrections[0]?.supportingTraceCount).toBeGreaterThanOrEqual(15);
  });

  it('runGeometryCorrectionsJob inserts road_geometry_corrections only', async () => {
    const insertRoadGeometryCorrections = vi.fn(async () => 1);
    const stats = await runGeometryCorrectionsJob({
      beginJobRun: vi.fn(async () => ({
        id: 'job-gc-1',
        jobName: 'geometry-corrections',
        status: 'running' as const,
      })),
      finishJobRun: vi.fn(async () => undefined),
      loadGeometryCorrectionsConfig: vi.fn(async () => ({
        minSupportingTraces: 15,
        clusterM: 20,
        minConfidence: 0.6,
      })),
      listMatchedTracesForGeometryCorrections: vi.fn(async () =>
        Array.from({ length: 16 }, (_, i) => ({
          tripId: `trip-${i}`,
          cityId: 'city-1',
          confidence: 0.9,
          matchMeta: {
            low_confidence_segments: [{
              lng: 7.401,
              lat: 9.001,
              confidence: 0.4,
            }],
          },
        })),
      ),
      insertRoadGeometryCorrections,
    });

    expect(stats.corrections_inserted).toBe(1);
    expect(insertRoadGeometryCorrections).toHaveBeenCalledOnce();
  });
});
