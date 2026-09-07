import {
  buildCorridorBundle,
  parseCorridorManifest,
  type CorridorManifest,
} from '@along/contracts';

export type { CorridorManifest };
export { buildCorridorBundle, parseCorridorManifest };

export type CorridorImportDiffRow = {
  entity: string;
  action: 'create' | 'skip';
  reason?: string | null;
  [key: string]: unknown;
};

export function loadCorridorManifestFromFiles(files: {
  corridor: { name: string; slug: string };
  parksCsv: string;
  routesCsv: string;
  stagesCsv: string;
  legFaresCsv: string;
  throughFaresCsv?: string;
}): CorridorManifest {
  return {
    corridor: files.corridor,
    parks: files.parksCsv,
    routes: files.routesCsv,
    stages: files.stagesCsv,
    leg_fares: files.legFaresCsv,
    through_fares: files.throughFaresCsv,
  };
}

export function validateCorridorManifest(manifest: CorridorManifest) {
  return parseCorridorManifest(manifest);
}

export function corridorImportPayload(manifest: CorridorManifest): string {
  const built = buildCorridorBundle(manifest);
  if (!built.ok) {
    throw new Error(built.errors.join('; '));
  }
  return JSON.stringify(built.bundle);
}

export function summarizeCorridorDiff(diff: CorridorImportDiffRow[]) {
  const creates = diff.filter((row) => row.action === 'create');
  const byEntity = creates.reduce<Record<string, number>>((acc, row) => {
    acc[row.entity] = (acc[row.entity] ?? 0) + 1;
    return acc;
  }, {});
  return { totalCreates: creates.length, byEntity };
}
