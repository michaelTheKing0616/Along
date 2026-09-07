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
import type {
  GeometryCorrectionInsert,
  GeometryCorrectionsJobConfig,
} from './geometry-corrections.js';
import type {
  MatchedTraceForInference,
  RouteInferenceCandidateInsert,
  RouteInferenceJobConfig,
} from './route-inference.js';
import type { MatchedTraceForGeometry } from './geometry-corrections.js';
import type {
  AnonymizedExportDb,
  AnonymizedExportJobConfig,
} from './anonymized-export.js';
import type { OdAggregateCell } from './anonymized-export-core.js';

export type JobsDb = AnonymizedExportDb & {
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
  loadRouteInferenceConfig(cityId?: string): Promise<RouteInferenceJobConfig>;
  listMatchedTracesForInference(minConfidence: number): Promise<MatchedTraceForInference[]>;
  insertRouteInferenceCandidates(candidates: RouteInferenceCandidateInsert[]): Promise<number>;
  loadGeometryCorrectionsConfig(cityId?: string): Promise<GeometryCorrectionsJobConfig>;
  listMatchedTracesForGeometryCorrections(): Promise<MatchedTraceForGeometry[]>;
  insertRoadGeometryCorrections(corrections: GeometryCorrectionInsert[]): Promise<number>;
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

    async loadRouteInferenceConfig(cityId) {
      const { rows } = await pool.query<{
        min_trips: string;
        frechet_m: string;
        min_confidence: string;
      }>(
        `select
           cfg_num('inference.min_trips', $1::uuid) as min_trips,
           cfg_num('inference.frechet_m', $1::uuid) as frechet_m,
           cfg_num('jobs.map_match_min_confidence', $1::uuid) as min_confidence`,
        [cityId ?? null],
      );
      const row = rows[0];
      return {
        minTrips: Number(row?.min_trips ?? 20),
        frechetM: Number(row?.frechet_m ?? 150),
        minConfidence: Number(row?.min_confidence ?? 0.6),
      } satisfies RouteInferenceJobConfig;
    },

    async listMatchedTracesForInference(minConfidence) {
      const { rows } = await pool.query<{
        trip_id: string;
        city_id: string;
        mode_code: string;
        confidence: string;
        geometry: import('./types.js').GeoJsonLineString;
        match_meta: Record<string, unknown> | null;
      }>(
        `select
           t.id as trip_id,
           j.city_id,
           t.mode_code,
           mt.confidence::text,
           st_asgeojson(mt.geometry)::jsonb as geometry,
           mt.match_meta
         from matched_traces mt
         join trips t on t.id = mt.trip_id
         join journeys j on j.id = t.journey_id
         where mt.actor_type = 'driver'
           and mt.confidence >= $1
           and st_npoints(mt.geometry::geometry) >= 2`,
        [minConfidence],
      );

      return rows.map((row) => ({
        tripId: row.trip_id,
        cityId: row.city_id,
        modeCode: row.mode_code,
        confidence: Number(row.confidence),
        geometryGeoJson: row.geometry as import('./types.js').GeoJsonLineString,
        matchMeta: row.match_meta ?? {},
      })) satisfies MatchedTraceForInference[];
    },

    async insertRouteInferenceCandidates(candidates) {
      if (candidates.length === 0) return 0;

      let inserted = 0;
      for (const candidate of candidates) {
        const { rowCount } = await pool.query(
          `insert into route_inference_candidates (
             city_id,
             mode_code,
             geometry,
             origin_cluster,
             destination_cluster,
             supporting_trip_count,
             status
           )
           select
             $1,
             $2,
             st_geogfromgeojson($3),
             st_setsrid(st_makepoint($4, $5), 4326)::geography,
             st_setsrid(st_makepoint($6, $7), 4326)::geography,
             $8,
             'new'
           where not exists (
             select 1
             from route_inference_candidates ric
             where ric.city_id = $1
               and ric.mode_code = $2
               and ric.status = 'new'
               and st_dwithin(
                 ric.origin_cluster,
                 st_setsrid(st_makepoint($4, $5), 4326)::geography,
                 cfg_num('inference.frechet_m', $1::uuid)
               )
               and st_dwithin(
                 ric.destination_cluster,
                 st_setsrid(st_makepoint($6, $7), 4326)::geography,
                 cfg_num('inference.frechet_m', $1::uuid)
               )
           )`,
          [
            candidate.cityId,
            candidate.modeCode,
            JSON.stringify(candidate.geometryGeoJson),
            candidate.originLng,
            candidate.originLat,
            candidate.destinationLng,
            candidate.destinationLat,
            candidate.supportingTripCount,
          ],
        );
        inserted += rowCount ?? 0;
      }
      return inserted;
    },

    async loadGeometryCorrectionsConfig(cityId) {
      const { rows } = await pool.query<{
        min_supporting_traces: string;
        cluster_m: string;
        min_confidence: string;
      }>(
        `select
           cfg_num('geometry.min_supporting_traces', $1::uuid) as min_supporting_traces,
           cfg_num('geometry.cluster_m', $1::uuid) as cluster_m,
           cfg_num('jobs.map_match_min_confidence', $1::uuid) as min_confidence`,
        [cityId ?? null],
      );
      const row = rows[0];
      return {
        minSupportingTraces: Number(row?.min_supporting_traces ?? 15),
        clusterM: Number(row?.cluster_m ?? 20),
        minConfidence: Number(row?.min_confidence ?? 0.6),
      } satisfies GeometryCorrectionsJobConfig;
    },

    async listMatchedTracesForGeometryCorrections() {
      const { rows } = await pool.query<{
        trip_id: string;
        city_id: string;
        confidence: string;
        match_meta: Record<string, unknown> | null;
      }>(
        `select
           t.id as trip_id,
           j.city_id,
           mt.confidence::text,
           mt.match_meta
         from matched_traces mt
         join trips t on t.id = mt.trip_id
         join journeys j on j.id = t.journey_id
         where mt.actor_type = 'driver'
           and mt.match_meta is not null`,
      );

      return rows.map((row) => ({
        tripId: row.trip_id,
        cityId: row.city_id,
        confidence: Number(row.confidence),
        matchMeta: row.match_meta ?? {},
      })) satisfies MatchedTraceForGeometry[];
    },

    async insertRoadGeometryCorrections(corrections) {
      if (corrections.length === 0) return 0;

      let inserted = 0;
      for (const correction of corrections) {
        const { rowCount } = await pool.query(
          `insert into road_geometry_corrections (
             city_id,
             geometry,
             supporting_trace_count,
             status
           )
           select
             $1,
             st_geogfromgeojson($2),
             $3,
             'candidate'
           where not exists (
             select 1
             from road_geometry_corrections rgc
             where rgc.city_id = $1
               and rgc.status = 'candidate'
               and st_dwithin(
                 rgc.geometry,
                 st_geogfromgeojson($2),
                 cfg_num('geometry.cluster_m', $1::uuid)
               )
           )`,
          [
            correction.cityId,
            JSON.stringify(correction.geometryGeoJson),
            correction.supportingTraceCount,
          ],
        );
        inserted += rowCount ?? 0;
      }
      return inserted;
    },

    async loadAnonymizedExportConfig(cityId) {
      const { rows } = await pool.query<{
        k: string;
        geohash_precision: string;
      }>(
        `select
           cfg_num('export.k', $1::uuid) as k,
           cfg_num('export.geohash_precision', $1::uuid) as geohash_precision`,
        [cityId ?? null],
      );
      const row = rows[0];
      return {
        kAnonymity: Number(row?.k ?? 10),
        geohashPrecision: Number(row?.geohash_precision ?? 5),
      } satisfies AnonymizedExportJobConfig;
    },

    async listActiveCityIds() {
      const { rows } = await pool.query<{ id: string }>(
        `select id from cities where status = 'live' order by slug`,
      );
      return rows.map((row) => row.id);
    },

    async getExportWatermark(cityId) {
      const { rows } = await pool.query<{ period_end: Date | null }>(
        `select max(e.period_end) as period_end
         from anonymized_od_exports e
         join job_runs jr on jr.id = e.job_run_id
         where e.city_id = $1
           and jr.status = 'succeeded'`,
        [cityId],
      );
      return rows[0]?.period_end ?? null;
    },

    async aggregateCityOdCells(input) {
      const { rows: tripRows } = await pool.query<{ count: string }>(
        `select count(*)::text as count
         from trips t
         join journeys j on j.id = t.journey_id
         where j.city_id = $1
           and t.status = 'completed'
           and coalesce(t.ended_at, t.started_at, t.requested_at) >= $2
           and coalesce(t.ended_at, t.started_at, t.requested_at) < $3`,
        [input.cityId, input.periodStart, input.periodEnd],
      );

      const { rows: cellRows } = await pool.query<{
        origin_geohash: string;
        destination_geohash: string;
        mode_code: string;
        dow_bucket: number;
        hour_bucket: number;
        trip_count: string;
      }>(
        `select
           origin_geohash,
           destination_geohash,
           mode_code,
           dow_bucket,
           hour_bucket,
           trip_count::text
         from private.aggregate_anonymized_od_cells($1, $2, $3, $4, $5)`,
        [
          input.cityId,
          input.periodStart,
          input.periodEnd,
          input.kAnonymity,
          input.geohashPrecision,
        ],
      );

      const { rows: suppressedRows } = await pool.query<{ count: string }>(
        `select private.count_suppressed_od_cells($1, $2, $3, $4, $5)::text as count`,
        [
          input.cityId,
          input.periodStart,
          input.periodEnd,
          input.kAnonymity,
          input.geohashPrecision,
        ],
      );

      const cells: OdAggregateCell[] = cellRows.map((row) => ({
        originGeohash: row.origin_geohash,
        destinationGeohash: row.destination_geohash,
        modeCode: row.mode_code,
        dowBucket: row.dow_bucket as 0 | 1,
        hourBucket: row.hour_bucket,
        tripCount: Number(row.trip_count),
      }));

      return {
        tripsExamined: Number(tripRows[0]?.count ?? 0),
        cells,
        rawCellCount: cells.length + Number(suppressedRows[0]?.count ?? 0),
        cellsSuppressed: Number(suppressedRows[0]?.count ?? 0),
      };
    },

    async writeAnonymizedExport(input) {
      const client = await pool.connect();
      try {
        await client.query('begin');

        const { rows: exportRows } = await client.query<{ id: string }>(
          `insert into anonymized_od_exports (
             job_run_id,
             city_id,
             period_start,
             period_end,
             k_threshold,
             geohash_precision,
             trips_examined,
             cells_emitted,
             cells_suppressed
           ) values ($1, $2, $3, $4, $5, $6, $7, $8, $9)
           returning id`,
          [
            input.jobRunId,
            input.cityId,
            input.periodStart,
            input.periodEnd,
            input.kThreshold,
            input.geohashPrecision,
            input.tripsExamined,
            input.cells.length,
            input.cellsSuppressed,
          ],
        );
        const exportId = exportRows[0]?.id;
        if (!exportId) {
          throw new Error('failed to create anonymized_od_exports row');
        }

        for (const cell of input.cells) {
          await client.query(
            `insert into anonymized_od_cells (
               export_id,
               city_id,
               origin_geohash,
               destination_geohash,
               mode_code,
               dow_bucket,
               hour_bucket,
               trip_count
             ) values ($1, $2, $3, $4, $5, $6, $7, $8)`,
            [
              exportId,
              input.cityId,
              cell.originGeohash,
              cell.destinationGeohash,
              cell.modeCode,
              cell.dowBucket,
              cell.hourBucket,
              cell.tripCount,
            ],
          );
        }

        await client.query('commit');
        return exportId;
      } catch (err) {
        await client.query('rollback');
        throw err;
      } finally {
        client.release();
      }
    },
  };
}

export async function closePgJobsDb(db: JobsDb & { pool?: pg.Pool }): Promise<void> {
  if ('pool' in db && db.pool) {
    await db.pool.end();
  }
}
