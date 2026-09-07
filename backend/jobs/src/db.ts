import pg from 'pg';

import type { JobRunRecord } from './map-match.js';
import type {
  MapMatchJobConfig,
  PendingTraceMatch,
  TraceActorType,
  TraceSample,
} from './types.js';
import type { SpeedProfileAggregate } from './segment-observations.js';
import type { MatchedTraceForSpeed } from './segment-observations.js';
import type { SpeedProfilesJobConfig } from './speed-profiles.js';

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
  insertMatchedTrace(record: import('./types.js').MatchedTraceRecord): Promise<boolean>;
  loadSpeedProfilesConfig(cityId?: string): Promise<SpeedProfilesJobConfig>;
  listMatchedTracesForSpeedProfiles(minConfidence: number): Promise<MatchedTraceForSpeed[]>;
  upsertSpeedProfiles(profiles: SpeedProfileAggregate[]): Promise<number>;
};

const { Pool } = pg;

export type PgJobsDbOptions = {
  connectionString?: string;
  pool?: pg.Pool;
};

export function createPgJobsDb(options?: PgJobsDbOptions): JobsDb {
  const pool = options?.pool ?? new Pool({
    connectionString:
      options?.connectionString ??
      process.env.DATABASE_URL ??
      'postgresql://postgres:postgres@127.0.0.1:54322/postgres',
  });

  return {
    async beginJobRun(jobName, params = {}) {
      const { rows } = await pool.query<{ id: string }>(
        `insert into job_runs (job_name, params)
         values ($1, $2::jsonb)
         returning id`,
        [jobName, JSON.stringify(params)],
      );
      const row = rows[0];
      if (!row) {
        throw new Error('failed to create job_run');
      }
      return { id: row.id, jobName, status: 'running' } satisfies JobRunRecord;
    },

    async finishJobRun(jobRunId, status, stats, error) {
      await pool.query(
        `update job_runs
         set status = $2,
             finished_at = now(),
             stats = coalesce($3::jsonb, stats),
             error = $4
         where id = $1`,
        [jobRunId, status, stats ? JSON.stringify(stats) : null, error ?? null],
      );
    },

    async loadMapMatchConfig(cityId) {
      const { rows } = await pool.query<{
        min_samples: string;
        min_confidence: string;
        default_radius_m: string;
      }>(
        `select
           cfg_num('jobs.map_match_min_samples', $1::uuid) as min_samples,
           cfg_num('jobs.map_match_min_confidence', $1::uuid) as min_confidence,
           cfg_num('jobs.map_match_default_radius_m', $1::uuid) as default_radius_m`,
        [cityId ?? null],
      );
      const row = rows[0];
      return {
        minSamples: Number(row?.min_samples ?? 10),
        minConfidence: Number(row?.min_confidence ?? 0.6),
        osrmBaseUrl:
          process.env.OSRM_BASE_URL ??
          process.env.OSRM_URL ??
          '',
        osrmTimeoutMs: Number(process.env.OSRM_TIMEOUT_MS ?? '8000'),
        defaultRadiusM: Number(row?.default_radius_m ?? 25),
      } satisfies MapMatchJobConfig;
    },

    async listPendingTraceMatches(minSamples) {
      const { rows } = await pool.query<{
        trip_id: string;
        city_id: string;
        actor_type: TraceActorType;
        sample_count: string;
      }>(
        `select
           t.id as trip_id,
           j.city_id,
           tls.actor_type,
           count(*)::text as sample_count
         from trips t
         join journeys j on j.id = t.journey_id
         join trip_location_samples tls on tls.trip_id = t.id
         where t.status = 'completed'
           and tls.actor_type in ('driver', 'rider')
           and not exists (
             select 1
             from matched_traces mt
             where mt.trip_id = t.id
               and mt.actor_type = tls.actor_type
           )
         group by t.id, j.city_id, tls.actor_type
         having count(*) >= $1`,
        [minSamples],
      );

      return rows.map((row) => ({
        tripId: row.trip_id,
        cityId: row.city_id,
        actorType: row.actor_type,
        sampleCount: Number(row.sample_count),
      })) satisfies PendingTraceMatch[];
    },

    async loadTraceSamples(tripId, actorType) {
      const { rows } = await pool.query<{
        lng: number;
        lat: number;
        ts: Date;
        accuracy_m: string | null;
      }>(
        `select
           st_x(location::geometry) as lng,
           st_y(location::geometry) as lat,
           ts,
           accuracy_m
         from trip_location_samples
         where trip_id = $1
           and actor_type = $2
         order by ts asc`,
        [tripId, actorType],
      );

      return rows.map((row) => ({
        lng: Number(row.lng),
        lat: Number(row.lat),
        ts: row.ts,
        accuracyM: row.accuracy_m === null ? null : Number(row.accuracy_m),
      })) satisfies TraceSample[];
    },

    async insertMatchedTrace(record) {
      const { rowCount } = await pool.query(
        `insert into matched_traces (
           trip_id,
           actor_type,
           geometry,
           confidence,
           osm_way_ids,
           match_meta
         ) values (
           $1,
           $2,
           st_geogfromgeojson($3),
           $4,
           $5::bigint[],
           $6::jsonb
         )
         on conflict (trip_id, actor_type) do nothing`,
        [
          record.tripId,
          record.actorType,
          JSON.stringify(record.geometryGeoJson),
          record.confidence,
          record.osmWayIds,
          JSON.stringify(record.matchMeta),
        ],
      );
      return (rowCount ?? 0) > 0;
    },

    async loadSpeedProfilesConfig(cityId) {
      const { rows } = await pool.query<{
        min_samples: string;
        min_confidence: string;
      }>(
        `select
           cfg_num('jobs.speed_profile_min_samples', $1::uuid) as min_samples,
           cfg_num('jobs.map_match_min_confidence', $1::uuid) as min_confidence`,
        [cityId ?? null],
      );
      const row = rows[0];
      return {
        minSamples: Number(row?.min_samples ?? 8),
        minConfidence: Number(row?.min_confidence ?? 0.6),
        timeZone: process.env.JOBS_TIMEZONE ?? 'Africa/Lagos',
      } satisfies SpeedProfilesJobConfig;
    },

    async listMatchedTracesForSpeedProfiles(minConfidence) {
      const { rows } = await pool.query<{
        city_id: string;
        confidence: string;
        osm_way_ids: string[];
        match_meta: Record<string, unknown> | null;
      }>(
        `select
           j.city_id,
           mt.confidence::text,
           coalesce(mt.osm_way_ids, '{}'::bigint[])::text[] as osm_way_ids,
           mt.match_meta
         from matched_traces mt
         join trips t on t.id = mt.trip_id
         join journeys j on j.id = t.journey_id
         where mt.confidence >= $1
           and (
             mt.match_meta ? 'segment_observations'
             or coalesce(array_length(mt.osm_way_ids, 1), 0) > 0
           )`,
        [minConfidence],
      );

      return rows.map((row) => ({
        cityId: row.city_id,
        confidence: Number(row.confidence),
        osmWayIds: row.osm_way_ids.map((id) => Number(id)),
        matchMeta: row.match_meta ?? {},
      })) satisfies MatchedTraceForSpeed[];
    },

    async upsertSpeedProfiles(profiles) {
      if (profiles.length === 0) return 0;

      let upserted = 0;
      for (const profile of profiles) {
        const { rowCount } = await pool.query(
          `insert into segment_speed_profiles (
             segment_key,
             city_id,
             dow_bucket,
             hour_bucket,
             median_speed_mps,
             p85_speed_mps,
             sample_count,
             updated_at
           ) values ($1, $2, $3, $4, $5, $6, $7, now())
           on conflict (segment_key, dow_bucket, hour_bucket) do update set
             city_id = excluded.city_id,
             median_speed_mps = excluded.median_speed_mps,
             p85_speed_mps = excluded.p85_speed_mps,
             sample_count = excluded.sample_count,
             updated_at = now()`,
          [
            profile.segmentKey,
            profile.cityId,
            profile.dowBucket,
            profile.hourBucket,
            profile.medianSpeedMps,
            profile.p85SpeedMps,
            profile.sampleCount,
          ],
        );
        upserted += rowCount ?? 0;
      }
      return upserted;
    },
  };
}

export async function closePgJobsDb(db: JobsDb & { pool?: pg.Pool }): Promise<void> {
  if ('pool' in db && db.pool) {
    await db.pool.end();
  }
}
