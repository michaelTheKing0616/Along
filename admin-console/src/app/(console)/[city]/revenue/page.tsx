import { getCityBySlug } from '@/lib/city/resolve';
import type {
  AnonymizedExportRow,
  ApiKeyRow,
  DeploymentOption,
  RevenueCorporateAccountRow,
  RevenueOperatorAccountRow,
  SponsoredPlacementRow,
} from '@/lib/revenue/types';
import { createClient } from '@/lib/supabase/server';
import { fromUntyped } from '@/lib/supabase/untyped';
import { RevenueConsole } from './revenue-console';

interface PageProps {
  params: Promise<{ city: string }>;
}

async function loadRevenueData(cityId: string) {
  const supabase = await createClient();

  const [{ data: deployments }, { data: exportK }] = await Promise.all([
    supabase.from('deployments').select('id, tenant_name').order('tenant_name'),
    supabase.rpc('cfg_num', { p_key: 'export.k', p_city: cityId }),
  ]);

  const { data: placementRows } = await fromUntyped(supabase, 'sponsored_placements')
    .select('id, context_type, target_reference, advertiser, content, active_from, active_to')
    .order('created_at', { ascending: false })
    .limit(100);

  const placementIds = ((placementRows ?? []) as Array<{ id: string }>).map((p) => p.id);
  const countersByPlacement = new Map<string, { impressions: number; taps: number }>();

  if (placementIds.length > 0) {
    const { data: counterRows } = await fromUntyped(supabase, 'placement_counters')
      .select('placement_id, impressions, taps')
      .in('placement_id', placementIds);

    for (const row of (counterRows ?? []) as Array<Record<string, unknown>>) {
      const id = String(row.placement_id);
      const prev = countersByPlacement.get(id) ?? { impressions: 0, taps: 0 };
      countersByPlacement.set(id, {
        impressions: prev.impressions + Number(row.impressions ?? 0),
        taps: prev.taps + Number(row.taps ?? 0),
      });
    }
  }

  const placements: SponsoredPlacementRow[] = ((placementRows ?? []) as Array<
    Record<string, unknown>
  >).map((row) => {
    const totals = countersByPlacement.get(String(row.id)) ?? { impressions: 0, taps: 0 };
    return {
      id: String(row.id),
      context_type: String(row.context_type),
      target_reference: String(row.target_reference),
      advertiser: String(row.advertiser),
      content: (row.content as Record<string, unknown>) ?? {},
      active_from: String(row.active_from),
      active_to: String(row.active_to),
      impressions: totals.impressions,
      taps: totals.taps,
    };
  });

  const { data: keyRows } = await fromUntyped(supabase, 'api_keys')
    .select('id, owner_organization, scope, rate_limit_per_min, created_at, revoked_at')
    .order('created_at', { ascending: false });

  const keyIds = ((keyRows ?? []) as Array<{ id: string }>).map((k) => k.id);
  const usageByKey = new Map<string, number>();

  if (keyIds.length > 0) {
    const { data: usageRows } = await fromUntyped(supabase, 'api_usage')
      .select('api_key_id, calls')
      .in('api_key_id', keyIds);

    for (const row of (usageRows ?? []) as Array<Record<string, unknown>>) {
      const id = String(row.api_key_id);
      usageByKey.set(id, (usageByKey.get(id) ?? 0) + Number(row.calls ?? 0));
    }
  }

  const apiKeys: ApiKeyRow[] = ((keyRows ?? []) as Array<Record<string, unknown>>).map((row) => ({
    id: String(row.id),
    owner_organization: String(row.owner_organization),
    scope: (row.scope as string[]) ?? [],
    rate_limit_per_min: Number(row.rate_limit_per_min),
    created_at: String(row.created_at),
    revoked_at: (row.revoked_at as string | null) ?? null,
    total_calls: usageByKey.get(String(row.id)) ?? 0,
  }));

  const { data: corpRows } = await fromUntyped(supabase, 'corporate_accounts')
    .select('id, name, billing_email, status, monthly_budget, currency')
    .order('created_at', { ascending: false });

  const corporateAccounts: RevenueCorporateAccountRow[] = ((corpRows ?? []) as Array<
    Record<string, unknown>
  >).map((row) => ({
    id: String(row.id),
    name: String(row.name),
    billing_email: String(row.billing_email),
    status: String(row.status),
    monthly_budget: row.monthly_budget != null ? Number(row.monthly_budget) : null,
    currency: String(row.currency),
  }));

  const { data: opRows } = await fromUntyped(supabase, 'operator_accounts')
    .select('id, name, type, subscription_tier, billing_status')
    .order('created_at', { ascending: false });

  const operatorAccounts: RevenueOperatorAccountRow[] = ((opRows ?? []) as Array<
    Record<string, unknown>
  >).map((row) => ({
    id: String(row.id),
    name: String(row.name),
    type: String(row.type),
    subscription_tier: String(row.subscription_tier),
    billing_status: String(row.billing_status),
  }));

  const { data: exportRows } = await fromUntyped(supabase, 'anonymized_od_exports')
    .select(
      'id, city_id, period_start, period_end, k_threshold, cells_emitted, cells_suppressed, trips_examined, created_at'
    )
    .eq('city_id', cityId)
    .order('created_at', { ascending: false })
    .limit(50);

  const exports: AnonymizedExportRow[] = ((exportRows ?? []) as Array<Record<string, unknown>>).map(
    (row) => ({
      id: String(row.id),
      city_id: String(row.city_id),
      period_start: String(row.period_start),
      period_end: String(row.period_end),
      k_threshold: Number(row.k_threshold),
      cells_emitted: Number(row.cells_emitted),
      cells_suppressed: Number(row.cells_suppressed),
      trips_examined: Number(row.trips_examined),
      created_at: String(row.created_at),
    })
  );

  return {
    deployments: ((deployments ?? []) as DeploymentOption[]),
    placements,
    apiKeys,
    corporateAccounts,
    operatorAccounts,
    exports,
    exportK: exportK != null ? Number(exportK) : 10,
  };
}

export default async function RevenuePage({ params }: PageProps) {
  const { city: citySlug } = await params;
  const city = await getCityBySlug(citySlug);
  const revenue = city ? await loadRevenueData(city.id) : {
    deployments: [],
    placements: [],
    apiKeys: [],
    corporateAccounts: [],
    operatorAccounts: [],
    exports: [],
    exportK: 10,
  };

  return (
    <>
      <div className="page-header">
        <h1>Revenue hooks</h1>
        <p>
          Sponsored placements, API keys, business accounts, and anonymised data exports in <strong>{city?.name ?? citySlug}</strong>.
        </p>
      </div>
      {!city ? (
        <div className="error-banner" role="alert">
          City &quot;{citySlug}&quot; was not found in the database.
        </div>
      ) : null}
      <RevenueConsole citySlug={citySlug} {...revenue} />
    </>
  );
}
