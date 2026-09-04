export type ParkCsvRow = {
  line: number;
  name: string;
  lat: number;
  lng: number;
  aliases: string[];
};

export type ParkCsvParseResult =
  | { ok: true; rows: ParkCsvRow[] }
  | { ok: false; errors: string[] };

export type ParkImportDiffRow = {
  name: string;
  lat: number;
  lng: number;
  aliases: string[];
  action: 'create' | 'skip';
  reason?: string;
};

/** Parse backbone parks CSV: name,lat,lng[,aliases]. */
export function parseParksCsv(text: string): ParkCsvParseResult {
  const lines = text.split(/\r?\n/).map((l) => l.trim()).filter(Boolean);
  const errors: string[] = [];
  const rows: ParkCsvRow[] = [];

  for (let i = 0; i < lines.length; i++) {
    const lineNo = i + 1;
    const line = lines[i];
    if (lineNo === 1 && /^name\s*,/i.test(line)) continue;

    const parts = line.split(',').map((p) => p.trim());
    if (parts.length < 3) {
      errors.push(`Line ${lineNo}: expected name,lat,lng`);
      continue;
    }

    const [name, latStr, lngStr, aliasesRaw] = parts;
    const lat = Number(latStr);
    const lng = Number(lngStr);
    if (!name) {
      errors.push(`Line ${lineNo}: name is required`);
      continue;
    }
    if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
      errors.push(`Line ${lineNo}: lat/lng must be numbers`);
      continue;
    }

    const aliases = aliasesRaw
      ? aliasesRaw.split('|').map((a) => a.trim()).filter(Boolean)
      : [];

    rows.push({ line: lineNo, name, lat, lng, aliases });
  }

  if (errors.length > 0) return { ok: false, errors };
  return { ok: true, rows };
}

export function diffParksCsv(
  rows: ParkCsvRow[],
  existingNames: readonly string[]
): ParkImportDiffRow[] {
  const normalized = new Set(existingNames.map((n) => n.trim().toLowerCase()));

  return rows.map((row) => {
    const key = row.name.trim().toLowerCase();
    if (normalized.has(key)) {
      return {
        name: row.name,
        lat: row.lat,
        lng: row.lng,
        aliases: row.aliases,
        action: 'skip',
        reason: 'Park name already exists in city',
      };
    }
    return {
      name: row.name,
      lat: row.lat,
      lng: row.lng,
      aliases: row.aliases,
      action: 'create',
    };
  });
}
