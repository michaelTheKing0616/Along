import { ConsoleNav } from '@/components/along/ConsoleNav';
import { getCityBySlug } from '@/lib/city/resolve';
import { sortFlagsByScore } from '@/lib/integrity/format';
import type { IntegrityFlagRow } from '@/lib/integrity/types';
import { checkAdminRole, createClient } from '@/lib/supabase/server';
import { IntegrityQueue } from './integrity-queue';

const ACTION_FLAG_ROLES = ['superadmin', 'ops_lead', 'finance'] as const;

interface PageProps {
  params: Promise<{ city: string }>;
}

type RawFlag = {
  id: string;
  trip_id: string;
  driver_id: string;
  flag_type: IntegrityFlagRow['flag_type'];
  score: number;
  evidence: Record<string, unknown>;
  rider_trace_quality: string;
  corroborating_rider_count: number;
  status: IntegrityFlagRow['status'];
  created_at: string;
  drivers: {
    driver_code: string | null;
    city_id: string;
    profiles: { display_name: string | null } | null;
  } | null;
};

async function loadIntegrityQueue(cityId: string): Promise<IntegrityFlagRow[]> {
  const supabase = await createClient();

  const { data, error } = await supabase
    .from('trip_reconciliation_flags')
    .select(
      `
      id,
      trip_id,
      driver_id,
      flag_type,
      score,
      evidence,
      rider_trace_quality,
      corroborating_rider_count,
      status,
      created_at,
      drivers!inner (
        driver_code,
        city_id,
        profiles ( display_name )
      )
    `
    )
    .eq('drivers.city_id', cityId)
    .order('score', { ascending: false });

  if (error || !data) {
    console.error('[loadIntegrityQueue]', error?.message);
    return [];
  }

  const rows = data as unknown as RawFlag[];

  const driverIds = [...new Set(rows.map((r) => r.driver_id))];
  const { data: riskRows } = await supabase
    .from('driver_risk_scores')
    .select('driver_id, cancel_after_match_rate, open_flags')
    .in('driver_id', driverIds)
    .order('computed_at', { ascending: false });

  const riskByDriver = new Map<
    string,
    { cancel_after_match_rate: number; open_flags: number }
  >();
  for (const risk of riskRows ?? []) {
    if (!riskByDriver.has(risk.driver_id)) {
      riskByDriver.set(risk.driver_id, {
        cancel_after_match_rate: Number(risk.cancel_after_match_rate),
        open_flags: risk.open_flags,
      });
    }
  }

  const mapped: IntegrityFlagRow[] = rows.map((row) => {
    const risk = riskByDriver.get(row.driver_id);
    return {
      id: row.id,
      trip_id: row.trip_id,
      driver_id: row.driver_id,
      driver_name: row.drivers?.profiles?.display_name ?? null,
      driver_code: row.drivers?.driver_code ?? null,
      flag_type: row.flag_type,
      score: Number(row.score),
      evidence: row.evidence ?? {},
      rider_trace_quality: row.rider_trace_quality,
      corroborating_rider_count: row.corroborating_rider_count,
      status: row.status,
      created_at: row.created_at,
      risk_cancel_rate: risk?.cancel_after_match_rate ?? null,
      risk_open_flags: risk?.open_flags ?? null,
    };
  });

  return sortFlagsByScore(mapped);
}

export default async function IntegrityPage({ params }: PageProps) {
  const { city: citySlug } = await params;
  const city = await getCityBySlug(citySlug);
  const queue = city ? await loadIntegrityQueue(city.id) : [];
  const selectedId = queue.find((r) => r.status === 'open')?.id ?? queue[0]?.id ?? null;
  const canActionFlag = await checkAdminRole(ACTION_FLAG_ROLES);

  return (
    <>
      <div className="page-header">
        <h1>Integrity review</h1>
        <p>
          Reconciliation flags for <strong>{city?.name ?? citySlug}</strong> — clear or action
          with explicit standing transition (FM13).
        </p>
      </div>
      {!city ? (
        <div className="error-banner" role="alert">
          City &quot;{citySlug}&quot; was not found in the database.
        </div>
      ) : null}
      <ConsoleNav city={citySlug} />
      <IntegrityQueue
        citySlug={citySlug}
        initialRows={queue}
        initialSelectedId={selectedId}
        canActionFlag={canActionFlag}
      />
    </>
  );
}
