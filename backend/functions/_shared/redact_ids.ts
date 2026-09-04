/** Redact Nigerian ID number patterns from assistive OCR output (doc 12 §5). */

const NIN_PATTERN = /\b\d{11}\b/g;
const LICENSE_PATTERN = /\b[A-Z]{2,3}\d{6,8}[A-Z]?\b/g;
const GENERIC_LONG_DIGIT = /\b\d{8,}\b/g;

export function containsIdNumber(text: string): boolean {
  return /\b\d{11}\b/.test(text)
    || /\b[A-Z]{2,3}\d{6,8}[A-Z]?\b/.test(text)
    || /\b\d{8,}\b/.test(text);
}

export function redactIdNumbers(text: string): string {
  return text
    .replace(NIN_PATTERN, '[REDACTED]')
    .replace(LICENSE_PATTERN, '[REDACTED]')
    .replace(GENERIC_LONG_DIGIT, '[REDACTED]');
}

export function redactOcrFields(
  fields: Record<string, string>,
): Record<string, string> {
  const out: Record<string, string> = {};
  for (const [key, value] of Object.entries(fields)) {
    if (/id|nin|license|licence|number/i.test(key)) {
      continue;
    }
    out[key] = redactIdNumbers(value);
  }
  return out;
}

export function extractNormalizedId(
  documentType: string,
  fields: Record<string, string>,
): string | null {
  const raw = fields.id_number ?? fields.nin ?? fields.license_number ?? null;
  if (!raw) return null;

  if (documentType === 'nin') {
    const digits = raw.replace(/\D/g, '');
    return digits.length === 11 ? digits : null;
  }

  if (documentType === 'drivers_license') {
    const norm = raw.replace(/[^A-Za-z0-9]/g, '').toUpperCase();
    return norm.length >= 5 ? norm : null;
  }

  return null;
}
