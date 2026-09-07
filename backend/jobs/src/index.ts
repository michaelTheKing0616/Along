export const JOBS_VERSION = '0.1.0';

export { createOsrmMatchClient } from './osrm-match.js';
export type { OsrmMatchClient } from './osrm-match.js';
export { createPgJobsDb, closePgJobsDb } from './db.js';
export type { JobsDb } from './db.js';
export { runMapMatchJob } from './map-match.js';
export type { MapMatchDeps, MapMatchStats, JobRunRecord } from './map-match.js';
export { runSpeedProfilesJob } from './speed-profiles.js';
export type { SpeedProfilesDb, SpeedProfilesStats } from './speed-profiles.js';
export { runRouteInferenceJob, clusterTracesForRouteInference } from './route-inference.js';
export type {
  RouteInferenceDb,
  RouteInferenceStats,
  MatchedTraceForInference,
} from './route-inference.js';
export {
  runGeometryCorrectionsJob,
  extractLowConfidenceSegments,
  clusterGeometryCorrections,
} from './geometry-corrections.js';
export type {
  GeometryCorrectionsDb,
  GeometryCorrectionsStats,
} from './geometry-corrections.js';
export { discreteFrechetM } from './frechet.js';
export { proposeFromTraces } from './propose-from-traces.js';
export type { ProposeFromTracesInput, RawTraceInput } from './propose-from-traces.js';
export {
  aggregateSpeedProfiles,
  extractObservationsFromMatchedTrace,
} from './segment-observations.js';
export { runEtaAbReport } from './eta-ab.js';
export { runAnonymizedExportJob } from './anonymized-export.js';
export type {
  AnonymizedExportDb,
  AnonymizedExportJobConfig,
  AnonymizedExportStats,
} from './anonymized-export.js';
export {
  aggregateOdObservations,
  suppressCellsBelowK,
  partitionCellsByK,
  assertExportRowIsPiiFree,
  EXPORT_ALLOWED_COLUMNS,
  EXPORT_FORBIDDEN_COLUMNS,
} from './anonymized-export-core.js';
export type {
  GeoJsonLineString,
  MapMatchJobConfig,
  MatchedTraceRecord,
  OsrmMatchResult,
  PendingTraceMatch,
  TraceActorType,
  TraceProposal,
  TraceSample,
} from './types.js';

import { fileURLToPath } from 'node:url';

import { createOsrmMatchClient } from './osrm-match.js';
import { createPgJobsDb } from './db.js';
import { runMapMatchJob } from './map-match.js';
import { runSpeedProfilesJob } from './speed-profiles.js';
import { runRouteInferenceJob } from './route-inference.js';
import { runGeometryCorrectionsJob } from './geometry-corrections.js';
import { runAnonymizedExportJob } from './anonymized-export.js';

export async function main(argv: string[] = process.argv.slice(2)): Promise<void> {
  const command = argv[0];
  const db = createPgJobsDb();

  if (command === 'map-match') {
    const osrm = createOsrmMatchClient();
    const stats = await runMapMatchJob({ db, osrm });
    console.log(JSON.stringify({ job: 'map-match', stats }));
    return;
  }

  if (command === 'speed-profiles') {
    const stats = await runSpeedProfilesJob(db);
    console.log(JSON.stringify({ job: 'speed-profiles', stats }));
    return;
  }

  if (command === 'route-inference') {
    const stats = await runRouteInferenceJob(db);
    console.log(JSON.stringify({ job: 'route-inference', stats }));
    return;
  }

  if (command === 'geometry-corrections') {
    const stats = await runGeometryCorrectionsJob(db);
    console.log(JSON.stringify({ job: 'geometry-corrections', stats }));
    return;
  }

  if (command === 'anonymized-export') {
    const stats = await runAnonymizedExportJob(db);
    console.log(JSON.stringify({ job: 'anonymized-export', stats }));
    return;
  }

  throw new Error(`unknown jobs command: ${command ?? '(none)'}`);
}

const isMain = process.argv[1] === fileURLToPath(import.meta.url);
if (isMain) {
  main().catch((err: unknown) => {
    console.error(err);
    process.exitCode = 1;
  });
}
