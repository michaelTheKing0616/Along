import { buildI18nCoverage } from '@/lib/markets/i18n-coverage';
import type { CountryRow, DeploymentOption } from '@/lib/markets/types';
import { createClient } from '@/lib/supabase/server';
import { MarketsConsole } from './markets-console';

interface PageProps {
  params: Promise<{ city: string }>;
}

function parseVerificationSchema(raw: unknown): CountryRow['verification_schema'] {
  if (!Array.isArray(raw)) return [];
  return raw.flatMap((entry) => {
    if (!entry || typeof entry !== 'object') return [];
    const row = entry as Record<string, unknown>;
    const type = String(row.type ?? '').trim();
    if (!type) return [];
    return [
      {
        type,
        label: String(row.label ?? type),
        pattern: String(row.pattern ?? ''),
        provider: String(row.provider ?? 'verifyme'),
      },
    ];
  });
}

function parsePaymentProvider(raw: unknown): CountryRow['payment_provider'] {
  const value = String(raw ?? 'paystack').toLowerCase();
  if (value === 'flutterwave' || value === 'none') return value;
  return 'paystack';
}

async function loadMarketsData() {
  const supabase = await createClient();

  const [{ data: countryRows }, { data: deploymentRows }, { data: configRows }] = await Promise.all([
    supabase
      .from('countries')
      .select(
        'code, name, currency_code, currency_minor_units, currency_symbol, phone_prefix, default_locale, timezone, deployment_id, verification_schema, regulatory_flags, active'
      )
      .order('code'),
    supabase.from('deployments').select('id, tenant_name').eq('active', true).order('tenant_name'),
    supabase
      .from('app_config')
      .select('scope_id, value')
      .eq('key', 'payments.provider')
      .eq('scope_type', 'country'),
  ]);

  const providerByCountry = new Map<string, CountryRow['payment_provider']>();
  for (const row of configRows ?? []) {
    const code = String(row.scope_id ?? '');
    if (!code) continue;
    const value = row.value;
    const parsed =
      typeof value === 'string'
        ? value.replace(/^"|"$/g, '')
        : value != null && typeof value === 'object' && 'provider' in (value as object)
          ? String((value as { provider: unknown }).provider)
          : String(value ?? 'paystack');
    providerByCountry.set(code, parsePaymentProvider(parsed));
  }

  const countries: CountryRow[] = (countryRows ?? []).map((row) => ({
    code: row.code,
    name: row.name,
    currency_code: row.currency_code,
    currency_minor_units: row.currency_minor_units,
    currency_symbol: row.currency_symbol,
    phone_prefix: row.phone_prefix,
    default_locale: row.default_locale,
    timezone: row.timezone,
    deployment_id: row.deployment_id,
    verification_schema: parseVerificationSchema(row.verification_schema),
    regulatory_flags: (row.regulatory_flags as Record<string, unknown>) ?? {},
    active: row.active,
    payment_provider: providerByCountry.get(row.code) ?? 'paystack',
  }));

  const deployments: DeploymentOption[] = (deploymentRows ?? []).map((row) => ({
    id: row.id,
    tenant_name: row.tenant_name,
  }));

  const i18nCoverage = buildI18nCoverage(countries.map((c) => c.default_locale));

  return { countries, deployments, i18nCoverage };
}

export default async function MarketsPage({ params }: PageProps) {
  const { city: citySlug } = await params;
  const { countries, deployments, i18nCoverage } = await loadMarketsData();

  return (
    <>
      <div className="page-header">
        <h1>Markets &amp; portability</h1>
        <p>
          Countries, verification requirements, regulatory flags, translation coverage, and payment providers. All configuration; no code changes.
        </p>
      </div>
      <MarketsConsole
        citySlug={citySlug}
        countries={countries}
        deployments={deployments}
        i18nCoverage={i18nCoverage}
      />
    </>
  );
}
