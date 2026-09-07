/**
 * Corridor backbone CSV import (doc 13 §4, A-08).
 * Consumed by admin-console A-08 and data-collection import_corridor CLI.
 */

export type CorridorManifest = {
  corridor: { name: string; slug: string };
  parks: string;
  routes: string;
  stages: string;
  leg_fares: string;
  through_fares?: string;
};

export type ParsedParkRow = {
  line: number;
  name: string;
  aliases: string[];
  lat: number;
  lng: number;
  modes: string[];
};

export type ParsedRouteRow = {
  line: number;
  origin_park: string;
  destination_park: string;
  mode: string;
  name: string;
};

export type ParsedStageRow = {
  line: number;
  route_name: string;
  sequence: number;
  stage_name: string;
  lat: number;
  lng: number;
  is_official_park: boolean;
};

export type ParsedFareRow = {
  line: number;
  route_name: string;
  from_seq: number;
  to_seq: number;
  fare: number;
};

export type ParseResult<T> =
  | { ok: true; rows: T[] }
  | { ok: false; errors: string[] };

function splitCsvLine(line: string): string[] {
  return line.split(',').map((p) => p.trim());
}

function parseDataLines(text: string): string[] {
  return text
    .split(/\r?\n/)
    .map((l) => l.trim())
    .filter(Boolean)
    .filter((line, index, all) => !(index === 0 && /^[a-z_]+,/i.test(line) && all.length > 1));
}

function parseHeaderedLines(text: string): { lines: string[]; skipFirst: boolean } {
  const raw = text.split(/\r?\n/).map((l) => l.trim()).filter(Boolean);
  if (raw.length === 0) return { lines: [], skipFirst: false };
  const skipFirst = /^[a-z_]+,/i.test(raw[0] ?? '');
  return { lines: skipFirst ? raw.slice(1) : raw, skipFirst };
}

export function routeDisplayName(row: ParsedRouteRow): string {
  if (row.name.trim()) return row.name.trim();
  return `${row.origin_park} → ${row.destination_park} (${row.mode})`;
}

/** parks.csv: name,aliases|pipe,lat,lng[,modes|pipe] */
export function parseParksSection(text: string): ParseResult<ParsedParkRow> {
  const { lines } = parseHeaderedLines(text);
  const errors: string[] = [];
  const rows: ParsedParkRow[] = [];

  for (let i = 0; i < lines.length; i++) {
    const lineNo = i + 1;
    const parts = splitCsvLine(lines[i]!);
    if (parts.length < 3) {
      errors.push(`parks line ${lineNo}: expected name,aliases,lat,lng[,modes]`);
      continue;
    }
    const [name, aliasesRaw, latStr, lngStr, modesRaw] = parts;
    const lat = Number(latStr);
    const lng = Number(lngStr);
    if (!name) {
      errors.push(`parks line ${lineNo}: name is required`);
      continue;
    }
    if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
      errors.push(`parks line ${lineNo}: lat/lng must be numbers`);
      continue;
    }
    rows.push({
      line: lineNo,
      name,
      aliases: aliasesRaw ? aliasesRaw.split('|').map((a) => a.trim()).filter(Boolean) : [],
      lat,
      lng,
      modes: modesRaw ? modesRaw.split('|').map((m) => m.trim()).filter(Boolean) : [],
    });
  }

  if (errors.length > 0) return { ok: false, errors };
  return { ok: true, rows };
}

/** routes.csv: origin_park,destination_park,mode,name */
export function parseRoutesSection(text: string): ParseResult<ParsedRouteRow> {
  const { lines } = parseHeaderedLines(text);
  const errors: string[] = [];
  const rows: ParsedRouteRow[] = [];

  for (let i = 0; i < lines.length; i++) {
    const lineNo = i + 1;
    const parts = splitCsvLine(lines[i]!);
    if (parts.length < 3) {
      errors.push(`routes line ${lineNo}: expected origin_park,destination_park,mode[,name]`);
      continue;
    }
    const [origin_park, destination_park, mode, name = ''] = parts;
    if (!origin_park || !destination_park || !mode) {
      errors.push(`routes line ${lineNo}: origin, destination, and mode are required`);
      continue;
    }
    rows.push({ line: lineNo, origin_park, destination_park, mode, name });
  }

  if (errors.length > 0) return { ok: false, errors };
  return { ok: true, rows };
}

/** stages.csv: route_name,sequence,stage_name,lat,lng,is_official_park */
export function parseStagesSection(text: string): ParseResult<ParsedStageRow> {
  const { lines } = parseHeaderedLines(text);
  const errors: string[] = [];
  const rows: ParsedStageRow[] = [];

  for (let i = 0; i < lines.length; i++) {
    const lineNo = i + 1;
    const parts = splitCsvLine(lines[i]!);
    if (parts.length < 5) {
      errors.push(`stages line ${lineNo}: expected route_name,sequence,stage_name,lat,lng,is_official_park`);
      continue;
    }
    const [route_name, seqStr, stage_name, latStr, lngStr, officialRaw = 'false'] = parts;
    const sequence = Number(seqStr);
    const lat = Number(latStr);
    const lng = Number(lngStr);
    if (!route_name || !stage_name) {
      errors.push(`stages line ${lineNo}: route_name and stage_name are required`);
      continue;
    }
    if (!Number.isInteger(sequence) || sequence < 1) {
      errors.push(`stages line ${lineNo}: sequence must be a positive integer`);
      continue;
    }
    if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
      errors.push(`stages line ${lineNo}: lat/lng must be numbers`);
      continue;
    }
    rows.push({
      line: lineNo,
      route_name,
      sequence,
      stage_name,
      lat,
      lng,
      is_official_park: /^true|1|yes$/i.test(officialRaw),
    });
  }

  if (errors.length > 0) return { ok: false, errors };
  return { ok: true, rows };
}

/** leg_fares.csv / through_fares.csv: route_name,from_seq,to_seq,fare */
export function parseFaresSection(text: string, label: string): ParseResult<ParsedFareRow> {
  const { lines } = parseHeaderedLines(text);
  const errors: string[] = [];
  const rows: ParsedFareRow[] = [];

  for (let i = 0; i < lines.length; i++) {
    const lineNo = i + 1;
    const parts = splitCsvLine(lines[i]!);
    if (parts.length < 4) {
      errors.push(`${label} line ${lineNo}: expected route_name,from_seq,to_seq,fare`);
      continue;
    }
    const [route_name, fromStr, toStr, fareStr] = parts;
    const from_seq = Number(fromStr);
    const to_seq = Number(toStr);
    const fare = Number(fareStr);
    if (!route_name) {
      errors.push(`${label} line ${lineNo}: route_name is required`);
      continue;
    }
    if (!Number.isInteger(from_seq) || !Number.isInteger(to_seq)) {
      errors.push(`${label} line ${lineNo}: from_seq and to_seq must be integers`);
      continue;
    }
    if (!Number.isFinite(fare) || fare < 0) {
      errors.push(`${label} line ${lineNo}: fare must be a non-negative number`);
      continue;
    }
    rows.push({ line: lineNo, route_name, from_seq, to_seq, fare });
  }

  if (errors.length > 0) return { ok: false, errors };
  return { ok: true, rows };
}

export function parseCorridorManifest(manifest: CorridorManifest):
  | {
      ok: true;
      corridor: CorridorManifest['corridor'];
      parks: ParsedParkRow[];
      routes: ParsedRouteRow[];
      stages: ParsedStageRow[];
      leg_fares: ParsedFareRow[];
      through_fares: ParsedFareRow[];
    }
  | { ok: false; errors: string[] } {
  const errors: string[] = [];

  if (!manifest.corridor?.name?.trim() || !manifest.corridor?.slug?.trim()) {
    errors.push('corridor.name and corridor.slug are required');
  }

  const parks = parseParksSection(manifest.parks);
  const routes = parseRoutesSection(manifest.routes);
  const stages = parseStagesSection(manifest.stages);
  const leg_fares = parseFaresSection(manifest.leg_fares, 'leg_fares');
  const through_fares = parseFaresSection(manifest.through_fares ?? '', 'through_fares');

  for (const section of [parks, routes, stages, leg_fares]) {
    if (!section.ok) errors.push(...section.errors);
  }
  if (manifest.through_fares?.trim() && !through_fares.ok) {
    errors.push(...through_fares.errors);
  }

  if (errors.length > 0) return { ok: false, errors };

  if (!parks.ok || !routes.ok || !stages.ok || !leg_fares.ok) {
    return { ok: false, errors: ['Unexpected parse failure'] };
  }

  return {
    ok: true,
    corridor: manifest.corridor,
    parks: parks.rows,
    routes: routes.rows,
    stages: stages.rows,
    leg_fares: leg_fares.rows,
    through_fares: through_fares.ok ? through_fares.rows : [],
  };
}

export function buildCorridorBundle(manifest: CorridorManifest):
  | { ok: true; bundle: Record<string, unknown> }
  | { ok: false; errors: string[] } {
  const parsed = parseCorridorManifest(manifest);
  if (!parsed.ok) return parsed;

  return {
    ok: true,
    bundle: {
      kind: 'corridor',
      corridor: parsed.corridor,
      parks: parsed.parks.map((row) => ({
        name: row.name,
        lat: row.lat,
        lng: row.lng,
        name_aliases: row.aliases,
        modes: row.modes,
      })),
      routes: parsed.routes.map((row) => ({
        origin_park: row.origin_park,
        destination_park: row.destination_park,
        mode: row.mode,
        name: routeDisplayName(row),
      })),
      stages: parsed.stages.map((row) => ({
        route_name: row.route_name,
        sequence: row.sequence,
        stage_name: row.stage_name,
        lat: row.lat,
        lng: row.lng,
        is_official_park: row.is_official_park,
      })),
      leg_fares: parsed.leg_fares.map((row) => ({
        route_name: row.route_name,
        from_seq: row.from_seq,
        to_seq: row.to_seq,
        fare: row.fare,
      })),
      through_fares: parsed.through_fares.map((row) => ({
        route_name: row.route_name,
        from_seq: row.from_seq,
        to_seq: row.to_seq,
        fare: row.fare,
      })),
    },
  };
}

/** Bundle JSON passed to admin_import_dry_run when importing a corridor. */
export function corridorBundleJson(manifest: CorridorManifest): string {
  const built = buildCorridorBundle(manifest);
  if (!built.ok) {
    throw new Error(built.errors.join('; '));
  }
  return JSON.stringify(built.bundle);
}

export const CORRIDOR_IMPORT_RPC = {
  dryRun: 'admin_import_dry_run',
  apply: 'admin_import_apply',
} as const;

/** Paths that may change when adding a corridor — application code must stay untouched. */
export const CORRIDOR_DATA_ONLY_PREFIXES = [
  'data-collection/fixtures/',
  'backend/db/seed/',
] as const;

export const CORRIDOR_DATA_ONLY_EXTENSIONS = ['.csv', '.json', '.sql', '.md'] as const;
