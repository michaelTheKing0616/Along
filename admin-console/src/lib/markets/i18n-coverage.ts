import type { I18nCoverageRow } from './types';

/** Static union of rider + driver ARB keys (en base pack only — P10-B-01 adds locale packs). */
export const BASE_I18N_KEY_COUNT = 499;

const PACKAGED_LOCALES = new Set(['en', 'en-NG']);

function coverageForLocale(locale: string): I18nCoverageRow {
  const normalized = locale.trim();
  const packaged = PACKAGED_LOCALES.has(normalized);
  const translated = packaged ? BASE_I18N_KEY_COUNT : 0;
  return {
    locale: normalized,
    total_keys: BASE_I18N_KEY_COUNT,
    translated_keys: translated,
    coverage_pct: Math.round((translated / BASE_I18N_KEY_COUNT) * 100),
    source: packaged ? 'app_en.arb (rider + driver union)' : 'no locale pack yet',
  };
}

/** Build i18n coverage rows for locales referenced by active country catalog. */
export function buildI18nCoverage(locales: string[]): I18nCoverageRow[] {
  const unique = [...new Set(locales.map((l) => l.trim()).filter(Boolean))].sort();
  if (unique.length === 0) {
    return [coverageForLocale('en-NG')];
  }
  return unique.map(coverageForLocale);
}
