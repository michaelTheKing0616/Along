import type { JobRunRecord } from './map-match.js';
import {
  partitionCellsByK,
  type OdAggregateCell,
} from './anonymized-export-core.js';

export type AnonymizedExportJobConfig = {
  kAnonymity: number;
  geohashPrecision: number;
};

export type AnonymizedExportStats = {
  cities_processed: number;
  trips_examined: number;
  cells_emitted: number;
  cells_suppressed: number;
  exports_written: number;
};

export type AnonymizedExportCityResult = {
  cityId: string;
  periodStart: Date;
  periodEnd: Date;
  tripsExamined: number;
  cellsEmitted: OdAggregateCell[];
  cellsSuppressed: number;
  rawCellCount: number;
};

export type AnonymizedExportDb = {
  beginJobRun(jobName: string, params?: Record<string, unknown>): Promise<JobRunRecord>;
  finishJobRun(
    jobRunId: string,
    status: 'succeeded' | 'failed',
    stats?: Record<string, unknown>,
    error?: string,
  ): Promise<void>;
  loadAnonymizedExportConfig(cityId?: string): Promise<AnonymizedExportJobConfig>;
  listActiveCityIds(): Promise<string[]>;
  getExportWatermark(cityId: string): Promise<Date | null>;
  aggregateCityOdCells(input: {
    cityId: string;
    periodStart: Date;
    periodEnd: Date;
    kAnonymity: number;
    geohashPrecision: number;
  }): Promise<{
    tripsExamined: number;
    cells: OdAggregateCell[];
    rawCellCount: number;
    cellsSuppressed: number;
  }>;
  writeAnonymizedExport(input: {
    jobRunId: string;
    cityId: string;
    periodStart: Date;
    periodEnd: Date;
    kThreshold: number;
    geohashPrecision: number;
    tripsExamined: number;
    cells: OdAggregateCell[];
    cellsSuppressed: number;
  }): Promise<string>;
};

export async function runAnonymizedExportJob(
  db: AnonymizedExportDb,
  options: { periodEnd?: Date } = {},
): Promise<AnonymizedExportStats> {
  const periodEnd = options.periodEnd ?? new Date();
  const config = await db.loadAnonymizedExportConfig();
  const jobRun = await db.beginJobRun('anonymized-export', {
    k: config.kAnonymity,
    geohash_precision: config.geohashPrecision,
    period_end: periodEnd.toISOString(),
  });

  const stats: AnonymizedExportStats = {
    cities_processed: 0,
    trips_examined: 0,
    cells_emitted: 0,
    cells_suppressed: 0,
    exports_written: 0,
  };

  try {
    const cityIds = await db.listActiveCityIds();
    for (const cityId of cityIds) {
      const cityConfig = await db.loadAnonymizedExportConfig(cityId);
      const watermark = await db.getExportWatermark(cityId);
      const periodStart = watermark ?? new Date(0);

      const aggregated = await db.aggregateCityOdCells({
        cityId,
        periodStart,
        periodEnd,
        kAnonymity: cityConfig.kAnonymity,
        geohashPrecision: cityConfig.geohashPrecision,
      });

      const { emitted, suppressed } = partitionCellsByK(
        aggregated.cells,
        cityConfig.kAnonymity,
      );

      await db.writeAnonymizedExport({
        jobRunId: jobRun.id,
        cityId,
        periodStart,
        periodEnd,
        kThreshold: cityConfig.kAnonymity,
        geohashPrecision: cityConfig.geohashPrecision,
        tripsExamined: aggregated.tripsExamined,
        cells: emitted,
        cellsSuppressed: aggregated.cellsSuppressed || suppressed.length,
      });

      stats.cities_processed += 1;
      stats.trips_examined += aggregated.tripsExamined;
      stats.cells_emitted += emitted.length;
      stats.cells_suppressed += aggregated.cellsSuppressed || suppressed.length;
      stats.exports_written += 1;
    }

    await db.finishJobRun(jobRun.id, 'succeeded', stats);
    return stats;
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    await db.finishJobRun(jobRun.id, 'failed', stats, message);
    throw err;
  }
}
