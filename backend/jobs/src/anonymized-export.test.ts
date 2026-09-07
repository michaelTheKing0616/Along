import { describe, expect, it, vi } from 'vitest';

import { runAnonymizedExportJob } from './anonymized-export.js';
import {
  aggregateOdObservations,
  assertExportRowIsPiiFree,
  EXPORT_ALLOWED_COLUMNS,
  EXPORT_FORBIDDEN_COLUMNS,
  partitionCellsByK,
  sanitizeExportRow,
  suppressCellsBelowK,
  type OdObservation,
} from './anonymized-export-core.js';

function obs(
  originGeohash: string,
  destinationGeohash: string,
  overrides: Partial<OdObservation> = {},
): OdObservation {
  return {
    originGeohash,
    destinationGeohash,
    modeCode: 'car',
    dowBucket: 0,
    hourBucket: 10,
    ...overrides,
  };
}

describe('k-anonymity suppression (re-identification gate)', () => {
  it('suppresses singleton cells when k=10', () => {
    const observations = [
      ...Array.from({ length: 9 }, () => obs('s1t7d', 's1t7e')),
      obs('s0k8t', 's0k8u'),
    ];

    const aggregated = aggregateOdObservations(observations);
    const emitted = suppressCellsBelowK(aggregated, 10);

    expect(emitted).toHaveLength(0);
    expect(aggregated.some((cell) => cell.tripCount === 1)).toBe(true);
  });

  it('emits only cells with count >= k and never below', () => {
    const observations = [
      ...Array.from({ length: 12 }, () => obs('s1t7d', 's1t7e')),
      ...Array.from({ length: 3 }, () => obs('s0k8t', 's0k8u')),
      obs('s6hg5', 's6hg6'),
    ];

    const aggregated = aggregateOdObservations(observations);
    const { emitted, suppressed } = partitionCellsByK(aggregated, 10);

    expect(emitted).toHaveLength(1);
    expect(emitted[0]?.tripCount).toBe(12);
    expect(suppressed).toHaveLength(2);
    expect(emitted.every((cell) => cell.tripCount >= 10)).toBe(true);
    expect(suppressed.every((cell) => cell.tripCount < 10)).toBe(true);
  });

  it('partitions fixtures so no singleton survives export', () => {
    const observations = [
      obs('aaa', 'bbb'),
      obs('aaa', 'bbb'),
      obs('ccc', 'ddd'),
      obs('eee', 'fff'),
      obs('eee', 'fff'),
    ];

    const aggregated = aggregateOdObservations(observations);
    const { emitted, suppressed } = partitionCellsByK(aggregated, 2);

    expect(emitted.map((cell) => cell.tripCount).sort()).toEqual([2, 2]);
    expect(suppressed.map((cell) => cell.tripCount)).toEqual([1]);
    expect(emitted.every((cell) => cell.tripCount >= 2)).toBe(true);
  });
});

describe('PII-free export shape', () => {
  it('allows only aggregate OD columns', () => {
    for (const column of EXPORT_ALLOWED_COLUMNS) {
      expect(EXPORT_FORBIDDEN_COLUMNS).not.toContain(column);
    }
  });

  it('rejects rows containing rider, phone, plate, or coordinate fields', () => {
    for (const forbidden of EXPORT_FORBIDDEN_COLUMNS) {
      expect(() =>
        assertExportRowIsPiiFree({
          originGeohash: 's1t7d',
          destinationGeohash: 's1t7e',
          modeCode: 'car',
          dowBucket: 0,
          hourBucket: 10,
          tripCount: 12,
          [forbidden]: 'leak',
        }),
      ).toThrow(/forbidden column/);
    }
  });

  it('sanitizes export rows to the allowed aggregate schema', () => {
    const row = sanitizeExportRow(
      {
        originGeohash: 's1t7d',
        destinationGeohash: 's1t7e',
        modeCode: 'keke',
        dowBucket: 1,
        hourBucket: 18,
        tripCount: 15,
      },
      { cityId: 'city-1', exportId: 'export-1' },
    );

    expect(Object.keys(row).sort()).toEqual([...EXPORT_ALLOWED_COLUMNS].sort());
    expect(row).not.toHaveProperty('rider_id');
    expect(row).not.toHaveProperty('phone');
    expect(row).not.toHaveProperty('plate_number');
  });
});

describe('anonymized-export job orchestration', () => {
  it('writes only k-anonymous cells from aggregated observations', async () => {
    const writeAnonymizedExport = vi.fn(async () => 'export-1');
    const aggregateCityOdCells = vi.fn(async () => ({
      tripsExamined: 14,
      cells: [
        {
          originGeohash: 's1t7d',
          destinationGeohash: 's1t7e',
          modeCode: 'car',
          dowBucket: 0 as const,
          hourBucket: 10,
          tripCount: 12,
        },
      ],
      rawCellCount: 3,
      cellsSuppressed: 2,
    }));

    const db = {
      beginJobRun: vi.fn(async () => ({
        id: 'job-export-1',
        jobName: 'anonymized-export',
        status: 'running' as const,
      })),
      finishJobRun: vi.fn(async () => undefined),
      loadAnonymizedExportConfig: vi.fn(async () => ({
        kAnonymity: 10,
        geohashPrecision: 5,
      })),
      listActiveCityIds: vi.fn(async () => ['city-1']),
      getExportWatermark: vi.fn(async () => null),
      aggregateCityOdCells,
      writeAnonymizedExport,
    };

    const stats = await runAnonymizedExportJob(db, {
      periodEnd: new Date('2026-09-02T00:00:00Z'),
    });

    expect(stats.cells_emitted).toBe(1);
    expect(stats.cells_suppressed).toBe(2);
    expect(writeAnonymizedExport).toHaveBeenCalledWith(
      expect.objectContaining({
        cells: [expect.objectContaining({ tripCount: 12 })],
        cellsSuppressed: 2,
        kThreshold: 10,
      }),
    );
  });
});
