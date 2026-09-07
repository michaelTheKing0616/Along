import { describe, expect, it } from 'vitest';
import {
  assertConfigOnlyPayload,
  buildCountrySchemaPayload,
  buildCountryUpsertPayload,
  COUNTRY_SCHEMA_RPC_KEYS,
  COUNTRY_UPSERT_RPC_KEYS,
  ghanaHypotheticalForm,
} from './payload';

describe('markets country payload', () => {
  it('builds config-only admin_upsert_country payload for hypothetical GH', () => {
    const form = ghanaHypotheticalForm('a0000000-0000-4000-8000-000000000001');
    const payload = buildCountryUpsertPayload(form);

    expect(payload).toEqual({
      p_code: 'GH',
      p_name: 'Ghana',
      p_currency_code: 'GHS',
      p_currency_symbol: '₵',
      p_currency_minor_units: 2,
      p_phone_prefix: '+233',
      p_default_locale: 'en-GH',
      p_timezone: 'Africa/Accra',
      p_deployment_id: 'a0000000-0000-4000-8000-000000000001',
      p_regulatory_flags: { women_only_matching: false },
      p_active: false,
      p_payment_provider: 'paystack',
    });

    expect(() => assertConfigOnlyPayload(payload, COUNTRY_UPSERT_RPC_KEYS)).not.toThrow();
    expect(Object.keys(payload)).not.toContain('code_path');
    expect(Object.keys(payload)).not.toContain('p_code_path');
  });

  it('builds config-only admin_set_country_schema payload', () => {
    const form = ghanaHypotheticalForm('a0000000-0000-4000-8000-000000000001');
    const payload = buildCountrySchemaPayload(form.code, form.verification_schema);

    expect(payload.p_code).toBe('GH');
    expect(payload.p_verification_schema).toEqual([
      {
        type: 'ghana_card',
        label: 'Ghana Card',
        pattern: '^.{5,}$',
        provider: 'verifyme',
      },
    ]);

    expect(() => assertConfigOnlyPayload(payload, COUNTRY_SCHEMA_RPC_KEYS)).not.toThrow();
  });

  it('rejects payloads with code-path-like keys', () => {
    expect(() =>
      assertConfigOnlyPayload({ p_code: 'GH', code_path: 'src/gh.ts' }, [
        'p_code',
        'code_path',
      ])
    ).toThrow(/Forbidden code-path field/);
  });
});
