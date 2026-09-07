import { describe, expect, it, vi } from 'vitest';

import { createOsrmMatchClient } from './osrm-match.js';

describe('osrm match client', () => {
  it('calls car match with radiuses from sample accuracy', async () => {
    const fetchFn = vi.fn(async () => new Response(JSON.stringify({
      code: 'Ok',
      matchings: [{
        confidence: 0.91,
        geometry: {
          type: 'LineString',
          coordinates: [[7.4, 9.0], [7.41, 9.01]],
        },
      }],
    }), { status: 200 }));

    const client = createOsrmMatchClient({
      baseUrl: 'http://osrm.test',
      fetchFn,
    });

    const result = await client.carMatch([
      { lng: 7.4, lat: 9.0, ts: new Date('2026-01-01T10:00:00Z'), accuracyM: 18 },
      { lng: 7.41, lat: 9.01, ts: new Date('2026-01-01T10:00:05Z'), accuracyM: 22 },
    ], 25);

    expect(result.confidence).toBe(0.91);
    expect(result.degraded).toBe(false);
    expect(fetchFn).toHaveBeenCalledOnce();
    const calls = fetchFn.mock.calls as unknown as [string, RequestInit?][];
    const url = String(calls[0]?.[0]);
    expect(url).toContain('/match/v1/car/');
    expect(url).toContain('radiuses=18;22');
  });

  it('uses defaultRadiusM when accuracy_m is null', async () => {
    const fetchFn = vi.fn(async () => new Response(JSON.stringify({
      code: 'Ok',
      matchings: [{
        confidence: 0.88,
        geometry: {
          type: 'LineString',
          coordinates: [[7.4, 9.0], [7.41, 9.01]],
        },
      }],
    }), { status: 200 }));

    const client = createOsrmMatchClient({
      baseUrl: 'http://osrm.test',
      fetchFn,
    });

    await client.carMatch([
      { lng: 7.4, lat: 9.0, ts: new Date('2026-01-01T10:00:00Z'), accuracyM: null },
      { lng: 7.41, lat: 9.01, ts: new Date('2026-01-01T10:00:05Z'), accuracyM: 22 },
    ], 30);

    const calls = fetchFn.mock.calls as unknown as [string, RequestInit?][];
    const url = String(calls[0]?.[0]);
    expect(url).toContain('radiuses=30;22');
  });
});
