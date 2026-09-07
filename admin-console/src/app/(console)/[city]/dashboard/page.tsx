import { ConsoleNav } from '@/components/along/ConsoleNav';
import { aggregateSummaries } from '@/lib/analytics/format';
import type {
  CorridorAnalyticsResponse,
  CorridorOption,
  OpsDashboardCounts,
  OpsDashboardKpis,
} from '@/lib/analytics/types';
import { getCityBySlug } from '@/lib/city/resolve';
import { createClient } from '@/lib/supabase/server';
import { OpsDashboard } from './ops-dashboard';

interface PageProps {
  params: Promise<{ city: string }>;
}

async function loadCorridors(cityId: string): Promise<CorridorOption[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from('corridors')
    .select('id, name, slug')
    .eq('city_id', cityId)
    .order('name');

  if (error || !data) return [];
  return data;
}

async function loadAnalyticsForCorridor(
  corridorId: string,
  from: Date,
  to: Date
): Promise<CorridorAnalyticsResponse | null> {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc('admin_corridor_analytics', {
    p_corridor_id: corridorId,
    p_from: from.toISOString(),
    p_to: to.toISOString(),
  });

  if (error || !data) {
    console.error('[loadAnalyticsForCorridor]', error?.message);
    return null;
  }

  return data as unknown as CorridorAnalyticsResponse;
}

async function loadOpsCounts(cityId: string): Promise<OpsDashboardCounts> {
  const supabase = await createClient();

  const [
    { count: openSos },
    { count: openFlags },
    { count: verificationQueue },
    { data: presenceRows },
  ] = await Promise.all([
    supabase
      .from('sos_alerts')
      .select('id', { count: 'exact', head: true })
      .in('status', ['open', 'acknowledged']),
    supabase
      .from('trip_reconciliation_flags')
      .select('id, drivers!inner(city_id)', { count: 'exact', head: true })
      .eq('status', 'open')
      .eq('drivers.city_id', cityId),
    supabase
      .from('driver_verifications')
      .select('id, drivers!inner(city_id)', { count: 'exact', head: true })
      .eq('status', 'pending')
      .eq('drivers.city_id', cityId),
    supabase
      .from('driver_presence')
      .select('status, drivers!inner(city_id)')
      .neq('status', 'offline')
      .eq('drivers.city_id', cityId),
  ]);

  const driversOnline = presenceRows?.length ?? 0;
  const driversAtPark = presenceRows?.filter((row) => row.status === 'at_park').length ?? 0;
  const driversRoaming =
    presenceRows?.filter((row) => row.status !== 'at_park').length ?? 0;

  return {
    openSos: openSos ?? 0,
    openFlags: openFlags ?? 0,
    verificationQueue: verificationQueue ?? 0,
    driversOnline,
    driversAtPark,
    driversRoaming,
  };
}

export default async function DashboardPage({ params }: PageProps) {
  const { city: citySlug } = await params;
  const city = await getCityBySlug(citySlug);
  const to = new Date();
  const from = new Date(to.getTime() - 24 * 60 * 60 * 1000);

  let kpis: OpsDashboardKpis = {
    searches: 0,
    ambient_views: 0,
    commits: 0,
    ambient_to_commit_rate: null,
    ambient_to_commit_diagnostic: true,
    requests: 0,
    accept_rate: null,
    completed_trips: 0,
    fulfilment_rate: null,
    median_wait_s: 0,
    fare_discrepancy_rate: null,
    avg_candidates_per_search: 0,
    avg_direct_candidates: 0,
    coverage_gap_count: 0,
    corridors: 0,
  };
  let counts: OpsDashboardCounts = {
    openSos: 0,
    openFlags: 0,
    verificationQueue: 0,
    driversOnline: 0,
    driversAtPark: 0,
    driversRoaming: 0,
  };

  if (city) {
    const corridors = await loadCorridors(city.id);
    const analyticsRows = await Promise.all(
      corridors.map(async (corridor) => {
        const data = await loadAnalyticsForCorridor(corridor.id, from, to);
        return data ? { summary: data.summary } : null;
      })
    );
    const summaries = analyticsRows.filter((row): row is { summary: CorridorAnalyticsResponse['summary'] } => row != null);
    kpis = { ...aggregateSummaries(summaries), corridors: corridors.length };
    counts = await loadOpsCounts(city.id);
  }

  return (
    <>
      <div className="page-header">
        <h1>Ops dashboard</h1>
        <p>
          City KPIs for <strong>{city?.name ?? citySlug}</strong> — last 24 hours.
        </p>
      </div>
      {!city ? (
        <div className="error-banner" role="alert">
          City &quot;{citySlug}&quot; was not found in the database.
        </div>
      ) : null}
      <ConsoleNav city={citySlug} />
      <OpsDashboard citySlug={citySlug} windowLabel="24 h" kpis={kpis} counts={counts} />
    </>
  );
}
