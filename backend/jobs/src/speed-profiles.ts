import type { JobRunRecord } from './map-match.js';
import {
  aggregateSpeedProfiles,
  extractObservationsFromMatchedTrace,
  type SpeedProfileAggregate,
} from './segment-observations.js';
import type { MatchedTraceForSpeed } from './segment-observations.js';

export type SpeedProfilesJobConfig = {
  minSamples: number;
  minConfidence: number;
  timeZone: string;
};

export type SpeedProfilesStats = {
  traces_examined: number;
  observations_extracted: number;
  profiles_upserted: number;
  skipped_low_confidence: number;
  skipped_no_observations: number;
};

export type SpeedProfilesDb = {
  beginJobRun(jobName: string, params?: Record<string, unknown>): Promise<JobRunRecord>;
  finishJobRun(
    jobRunId: string,
    status: 'succeeded' | 'failed',
    stats?: Record<string, unknown>,
    error?: string,
  ): Promise<void>;
  loadSpeedProfilesConfig(cityId?: string): Promise<SpeedProfilesJobConfig>;
  listMatchedTracesForSpeedProfiles(minConfidence: number): Promise<MatchedTraceForSpeed[]>;
  upsertSpeedProfiles(profiles: SpeedProfileAggregate[]): Promise<number>;
};

export async function runSpeedProfilesJob(
  db: SpeedProfilesDb,
): Promise<SpeedProfilesStats> {
  const config = await db.loadSpeedProfilesConfig();
  const jobRun = await db.beginJobRun('speed-profiles', {
    min_samples: config.minSamples,
    min_confidence: config.minConfidence,
  });

  const stats: SpeedProfilesStats = {
    traces_examined: 0,
    observations_extracted: 0,
    profiles_upserted: 0,
    skipped_low_confidence: 0,
    skipped_no_observations: 0,
  };

  try {
    const traces = await db.listMatchedTracesForSpeedProfiles(config.minConfidence);
    const observations: Array<{
      segmentKey: string;
      speedMps: number;
      observedAt: Date;
      cityId: string;
    }> = [];

    for (const trace of traces) {
      stats.traces_examined += 1;
      if (trace.confidence < config.minConfidence) {
        stats.skipped_low_confidence += 1;
        continue;
      }

      const extracted = extractObservationsFromMatchedTrace(trace);
      if (extracted.length === 0) {
        stats.skipped_no_observations += 1;
        continue;
      }

      for (const obs of extracted) {
        observations.push({ ...obs, cityId: trace.cityId });
      }
    }

    stats.observations_extracted = observations.length;
    const profiles = aggregateSpeedProfiles(
      observations,
      config.minSamples,
      config.timeZone,
    );
    stats.profiles_upserted = await db.upsertSpeedProfiles(profiles);
    await db.finishJobRun(jobRun.id, 'succeeded', stats);
    return stats;
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    await db.finishJobRun(jobRun.id, 'failed', stats, message);
    throw err;
  }
}
