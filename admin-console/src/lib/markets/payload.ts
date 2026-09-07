import type { CountryFormInput, VerificationDocRow } from './types';

/** RPC argument keys for admin_upsert_country — config-only, no application code paths. */
export const COUNTRY_UPSERT_RPC_KEYS = [
  'p_code',
  'p_name',
  'p_currency_code',
  'p_currency_symbol',
  'p_currency_minor_units',
  'p_phone_prefix',
  'p_default_locale',
  'p_timezone',
  'p_deployment_id',
  'p_regulatory_flags',
  'p_active',
  'p_payment_provider',
] as const;

/** RPC argument keys for admin_set_country_schema. */
export const COUNTRY_SCHEMA_RPC_KEYS = ['p_code', 'p_verification_schema'] as const;

const FORBIDDEN_SUBSTRINGS = [
  'code_path',
  'codepath',
  'handler',
  'module_path',
  'feature_branch',
  'app_route',
  'source_file',
];

export function buildCountryUpsertPayload(input: CountryFormInput): Record<string, unknown> {
  return {
    p_code: input.code.trim().toUpperCase(),
    p_name: input.name.trim(),
    p_currency_code: input.currency_code.trim().toUpperCase(),
    p_currency_symbol: input.currency_symbol.trim(),
    p_currency_minor_units: input.currency_minor_units,
    p_phone_prefix: input.phone_prefix.trim(),
    p_default_locale: input.default_locale.trim(),
    p_timezone: input.timezone.trim(),
    p_deployment_id: input.deployment_id,
    p_regulatory_flags: {
      women_only_matching: input.women_only_matching,
    },
    p_active: input.active,
    p_payment_provider: input.payment_provider,
  };
}

export function buildCountrySchemaPayload(
  code: string,
  schema: VerificationDocRow[]
): Record<string, unknown> {
  return {
    p_code: code.trim().toUpperCase(),
    p_verification_schema: schema.map((row) => ({
      type: row.type.trim(),
      label: row.label.trim(),
      pattern: row.pattern.trim(),
      provider: row.provider.trim(),
    })),
  };
}

export function assertConfigOnlyPayload(
  payload: Record<string, unknown>,
  allowedKeys: readonly string[]
): void {
  const allowed = new Set(allowedKeys);
  for (const key of Object.keys(payload)) {
    if (!allowed.has(key)) {
      throw new Error(`Disallowed payload key: ${key}`);
    }
    const lower = key.toLowerCase();
    for (const forbidden of FORBIDDEN_SUBSTRINGS) {
      if (lower.includes(forbidden)) {
        throw new Error(`Forbidden code-path field in payload: ${key}`);
      }
    }
  }
}

/** Hypothetical Ghana fixture for portability dry-runs (no bespoke app branches). */
export function ghanaHypotheticalForm(deploymentId: string): CountryFormInput {
  return {
    code: 'GH',
    name: 'Ghana',
    currency_code: 'GHS',
    currency_symbol: '₵',
    currency_minor_units: 2,
    phone_prefix: '+233',
    default_locale: 'en-GH',
    timezone: 'Africa/Accra',
    deployment_id: deploymentId,
    active: false,
    women_only_matching: false,
    payment_provider: 'paystack',
    verification_schema: [
      {
        type: 'ghana_card',
        label: 'Ghana Card',
        pattern: '^.{5,}$',
        provider: 'verifyme',
      },
    ],
  };
}
