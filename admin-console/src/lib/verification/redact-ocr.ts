type OcrExtract = Record<string, unknown>;

const REDACTED_KEYS = new Set([
  'id_number',
  'nin',
  'license_number',
  'document_number',
  'raw_id',
  'id_hash',
]);

function redactValue(key: string, value: unknown): unknown {
  if (REDACTED_KEYS.has(key)) {
    return '[redacted]';
  }
  if (value && typeof value === 'object' && !Array.isArray(value)) {
    return redactOcrExtract(value as OcrExtract);
  }
  return value;
}

/** Strip raw identity fields from OCR extract for verifier display (doc 06 A-04). */
export function redactOcrExtract(extract: OcrExtract | null | undefined): OcrExtract {
  if (!extract) return {};
  const out: OcrExtract = {};
  for (const [key, value] of Object.entries(extract)) {
    out[key] = redactValue(key, value);
  }
  return out;
}
