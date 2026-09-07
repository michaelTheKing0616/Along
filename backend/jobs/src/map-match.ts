import type {
  MapMatchJobConfig,
  MatchedTraceRecord,
  PendingTraceMatch,
  TraceActorType,
  TraceSample,
} from './types.js';

export type JobRunRecord = {
  id: string;
  jobName: string;
  status: 'running' | 'succeeded' | 'failed';
};

export type JobsDb = {
  beginJobRun(jobName: string, params?: Record<string, unknown>): Promise<JobRunRecord>;
  finishJobRun(
    jobRunId: string,
    status: 'succeeded' | 'failed',
    stats?: Record<string, unknown>,
    error?: string,
  ): Promise<void>;
  loadMapMatchConfig(cityId?: string): Promise<MapMatchJobConfig>;
  listPendingTraceMatches(minSamples: number): Promise<PendingTraceMatch[]>;
  loadTraceSamples(tripId: string, actorType: TraceActorType): Promise<TraceSample[]>;
  insertMatchedTrace(record: MatchedTraceRecord): Promise<boolean>;
};

export type MapMatchStats = {
  examined: number;
  matched: number;
  skipped_low_confidence: number;
  skipped_osrm_degraded: number;
  errors: number;
};

export type MapMatchDeps = {
  db: JobsDb;
  osrm: {
    carMatch(samples: TraceSample[], defaultRadiusM: number): Promise<{
      confidence: number;
      geometry: MatchedTraceRecord['geometryGeoJson'];
      osmWayIds: number[];
      matchMeta: Record<string, unknown>;
      degraded: boolean;
    }>;
  };
};

export async function runMapMatchJob(deps: MapMatchDeps): Promise<MapMatchStats> {
  const config = await deps.db.loadMapMatchConfig();
  const pending = await deps.db.listPendingTraceMatches(config.minSamples);
  const jobRun = await deps.db.beginJobRun('map-match', {
    min_samples: config.minSamples,
    min_confidence: config.minConfidence,
  });

  const stats: MapMatchStats = {
    examined: 0,
    matched: 0,
    skipped_low_confidence: 0,
    skipped_osrm_degraded: 0,
    errors: 0,
  };

  try {
    for (const item of pending) {
      stats.examined += 1;
      const cityConfig = await deps.db.loadMapMatchConfig(item.cityId);
      const samples = await deps.db.loadTraceSamples(item.tripId, item.actorType);
      if (samples.length < cityConfig.minSamples) {
        continue;
      }

      const result = await deps.osrm.carMatch(samples, cityConfig.defaultRadiusM);
      if (result.degraded) {
        stats.skipped_osrm_degraded += 1;
        continue;
      }

      if (result.confidence < cityConfig.minConfidence) {
        stats.skipped_low_confidence += 1;
        continue;
      }

      if (result.geometry.coordinates.length < 2) {
        stats.errors += 1;
        continue;
      }

      const inserted = await deps.db.insertMatchedTrace({
        tripId: item.tripId,
        actorType: item.actorType,
        confidence: result.confidence,
        geometryGeoJson: result.geometry,
        osmWayIds: result.osmWayIds,
        matchMeta: result.matchMeta,
      });
      if (inserted) {
        stats.matched += 1;
      }
    }

    await deps.db.finishJobRun(jobRun.id, 'succeeded', stats);
    return stats;
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    await deps.db.finishJobRun(jobRun.id, 'failed', stats, message);
    throw err;
  }
}
