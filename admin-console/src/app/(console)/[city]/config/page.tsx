import type { Json } from '@along/contracts/db.types';
import { getCityBySlug } from '@/lib/city/resolve';
import { fetchAuditLogForTarget } from '@/lib/supabase/server';
import { createClient } from '@/lib/supabase/server';
import type { ConfigKeyMeta, ConfigScope } from '@/lib/config/keys';
import { ConfigEditor } from './config-editor';

interface PageProps {
  params: Promise<{ city: string }>;
}

async function loadConfigKeys(): Promise<ConfigKeyMeta[]> {
  const supabase = await createClient();
  const { data } = await supabase
    .from('app_config_keys')
    .select('key, description, allowed_scopes, read_only, value_schema')
    .order('key');

  return ((data ?? []) as Array<{
    key: string;
    description: string | null;
    allowed_scopes: ConfigScope[];
    read_only: boolean;
    value_schema: Json;
  }>).map((row) => ({
    key: row.key,
    description: row.description,
    allowedScopes: row.allowed_scopes,
    readOnly: row.read_only,
    valueSchema: (row.value_schema as Record<string, unknown>) ?? null,
  }));
}

async function loadScopedValues(cityId: string, countryCode: string) {
  const supabase = await createClient();
  const { data } = await supabase
    .from('app_config')
    .select('key, scope_type, scope_id, value, updated_at')
    .order('key');

  const rows = data ?? [];
  return rows.filter(
    (row) =>
      row.scope_type === 'global' ||
      (row.scope_type === 'country' && row.scope_id === countryCode) ||
      (row.scope_type === 'city' && row.scope_id === cityId)
  );
}

export default async function ConfigPage({ params }: PageProps) {
  const { city: citySlug } = await params;
  const city = await getCityBySlug(citySlug);
  const keys = await loadConfigKeys();
  const scopedValues = city
    ? await loadScopedValues(city.id, city.country_code)
    : [];

  const defaultKey = keys.find((k) => k.key === 'graph.snap_radius_m') ?? keys[0];
  const auditHistory = defaultKey
    ? await fetchAuditLogForTarget(`${defaultKey.key}:global:*`)
    : [];

  return (
    <>
      <div className="page-header">
        <h1>Configuration</h1>
        <p>
          Runtime settings with validation and an effective-value preview. Every change needs a reason and is audited.
        </p>
      </div>
      {!city ? (
        <div className="error-banner" role="alert">
          City &quot;{citySlug}&quot; was not found in the database.
        </div>
      ) : null}
      <ConfigEditor
        citySlug={citySlug}
        cityId={city?.id ?? ''}
        countryCode={city?.country_code ?? 'NG'}
        keys={keys}
        scopedValues={scopedValues.map((row) => ({
          key: row.key,
          scopeType: row.scope_type as ConfigScope,
          scopeId: row.scope_id,
          value: row.value,
          updatedAt: row.updated_at,
        }))}
        initialAudit={auditHistory}
      />
    </>
  );
}
