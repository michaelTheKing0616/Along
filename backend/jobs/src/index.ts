export const JOBS_VERSION = '0.1.0';

export { createOsrmMatchClient } from './osrm-match.js';
export type { OsrmMatchClient } from './osrm-match.js';
export { createPgJobsDb, closePgJobsDb } from './db.js';
export { runMapMatchJob } from './map-match.js';
export type { JobsDb, MapMatchDeps, MapMatchStats } from './map-match.js';
export { proposeFromTraces } from './propose-from-traces.js';
export type { ProposeFromTracesInput, RawTraceInput } from './propose-from-traces.js';
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

export async function main(argv: string[] = process.argv.slice(2)): Promise<void> {
  const command = argv[0];
  if (command !== 'map-match') {
    throw new Error(`unknown jobs command: ${command ?? '(none)'}`);
  }

  const db = createPgJobsDb();
  const osrm = createOsrmMatchClient();
  const stats = await runMapMatchJob({ db, osrm });
  console.log(JSON.stringify({ job: 'map-match', stats }));
}

const isMain = process.argv[1] === fileURLToPath(import.meta.url);
if (isMain) {
  main().catch((err: unknown) => {
    console.error(err);
    process.exitCode = 1;
  });
}
