import { AuditDrawer } from '@/components/along/AuditDrawer';
import { getCityBySlug } from '@/lib/city/resolve';
import { sortCorrectionQueue } from '@/lib/corrections/format';
import type { FareCorrectionQueueRow } from '@/lib/corrections/types';
import { createClient } from '@/lib/supabase/server';
import { CorrectionsQueue } from './corrections-queue';

interface PageProps {
  params: Promise<{ city: string }>;
}

type MadGuardRow = {
  is_outlier: boolean;
  neighbour_median: number | null;
  mad: number | null;
};

type RawCorrectionRow = {
  id: string;
  status: FareCorrectionQueueRow['status'];
  created_at: string;
  proposed_fare: number;
  fare_shown: number | null;
  currency: string;
  submitter_role: string;
  submitted_by: string;
  trip_id: string | null;
  route_id: string | null;
  from_stage_id: string | null;
  to_stage_id: string | null;
  route_leg_id: string | null;
  route_through_fare_id: string | null;
  route_legs: {
    fare_amount: number;
    route_id: string;
    from_stage_id: string;
    routes: { corridors: { name: string } | null } | null;
    from_stage: { name: string | null } | null;
    to_stage: { name: string | null } | null;
  } | null;
  route_through_fares: {
    fare_amount: number;
    route_id: string;
    from_stage_id: string;
    routes: { corridors: { name: string } | null } | null;
    from_stage: { name: string | null } | null;
    to_stage: { name: string | null } | null;
  } | null;
  routes: {
    id: string;
    corridors: { name: string } | null;
  } | null;
  from_stage: { name: string | null } | null;
  to_stage: { name: string | null } | null;
  profiles: { display_name: string | null } | null;
};

async function loadMadFlag(
  supabase: Awaited<ReturnType<typeof createClient>>,
  routeId: string | null,
  fromStageId: string | null,
  proposedFare: number,
  cityId: string
): Promise<boolean> {
  if (!routeId || !fromStageId) return false;
  const { data } = await supabase.rpc('fare_outlier_guard', {
    p_route_id: routeId,
    p_from_stage_id: fromStageId,
    p_proposed_fare: proposedFare,
    p_city_id: cityId,
  });
  const row = (Array.isArray(data) ? data[0] : data) as MadGuardRow | null;
  return Boolean(row?.is_outlier);
}

function resolveRouteContext(row: RawCorrectionRow): {
  routeId: string | null;
  fromStageId: string | null;
  currentFare: number | null;
  routeLabel: string | null;
  stageFrom: string | null;
  stageTo: string | null;
  targetType: string | null;
  targetId: string | null;
} {
  if (row.route_legs) {
    return {
      routeId: row.route_legs.route_id,
      fromStageId: row.route_legs.from_stage_id,
      currentFare: row.route_legs.fare_amount,
      routeLabel: row.route_legs.routes?.corridors?.name ?? 'Route leg',
      stageFrom: row.route_legs.from_stage?.name ?? null,
      stageTo: row.route_legs.to_stage?.name ?? null,
      targetType: 'route_leg',
      targetId: row.route_leg_id,
    };
  }
  if (row.route_through_fares) {
    return {
      routeId: row.route_through_fares.route_id,
      fromStageId: row.route_through_fares.from_stage_id,
      currentFare: row.route_through_fares.fare_amount,
      routeLabel: row.route_through_fares.routes?.corridors?.name ?? 'Through fare',
      stageFrom: row.route_through_fares.from_stage?.name ?? null,
      stageTo: row.route_through_fares.to_stage?.name ?? null,
      targetType: 'route_through_fare',
      targetId: row.route_through_fare_id,
    };
  }
  return {
    routeId: row.route_id,
    fromStageId: row.from_stage_id,
    currentFare: row.fare_shown,
    routeLabel: row.routes?.corridors?.name ?? 'Stage pair',
    stageFrom: row.from_stage?.name ?? null,
    stageTo: row.to_stage?.name ?? null,
    targetType: null,
    targetId: null,
  };
}

function submitterLabel(
  row: RawCorrectionRow,
  riderTrust: Map<string, number>,
  driverVerified: Map<string, boolean>
): { label: string; trust: number | null } {
  if (row.submitter_role === 'system') {
    return { label: 'System (negotiation)', trust: null };
  }
  const name = row.profiles?.display_name ?? row.submitted_by.slice(0, 8);
  if (row.submitter_role === 'rider') {
    return {
      label: `Rider · ${name}`,
      trust: riderTrust.get(row.submitted_by) ?? null,
    };
  }
  if (row.submitter_role === 'driver') {
    const verified = driverVerified.get(row.submitted_by) ?? false;
    return {
      label: `Driver · ${name}${verified ? ' (verified)' : ''}`,
      trust: verified ? 1.0 : 0.2,
    };
  }
  return { label: row.submitter_role, trust: null };
}

async function loadCorrectionsQueue(cityId: string): Promise<FareCorrectionQueueRow[]> {
  const supabase = await createClient();

  const { data, error } = await supabase
    .from('fare_corrections')
    .select(
      `
      id,
      status,
      created_at,
      proposed_fare,
      fare_shown,
      currency,
      submitter_role,
      submitted_by,
      trip_id,
      route_id,
      from_stage_id,
      to_stage_id,
      route_leg_id,
      route_through_fare_id,
      route_legs (
        fare_amount,
        route_id,
        from_stage_id,
        routes ( corridors ( name ) ),
        from_stage:route_stages!route_legs_from_stage_id_fkey ( name ),
        to_stage:route_stages!route_legs_to_stage_id_fkey ( name )
      ),
      route_through_fares (
        fare_amount,
        route_id,
        from_stage_id,
        routes ( corridors ( name ) ),
        from_stage:route_stages!route_through_fares_from_stage_id_fkey ( name ),
        to_stage:route_stages!route_through_fares_to_stage_id_fkey ( name )
      ),
      routes ( id, corridors ( name ) ),
      from_stage:route_stages!fare_corrections_from_stage_id_fkey ( name ),
      to_stage:route_stages!fare_corrections_to_stage_id_fkey ( name ),
      profiles!fare_corrections_submitted_by_fkey ( display_name )
    `
    )
    .order('created_at', { ascending: true });

  if (error || !data) {
    console.error('[loadCorrectionsQueue]', error?.message);
    return [];
  }

  const rows = data as unknown as RawCorrectionRow[];
  const submitterIds = [...new Set(rows.map((r) => r.submitted_by))];

  const [{ data: riderRows }, { data: driverRows }] = await Promise.all([
    supabase.from('riders').select('id, account_trust_weight').in('id', submitterIds),
    supabase.from('drivers').select('id, verified_status').in('id', submitterIds),
  ]);

  const riderTrust = new Map(
    (riderRows ?? []).map((r) => [r.id, Number(r.account_trust_weight)])
  );
  const driverVerified = new Map(
    (driverRows ?? []).map((d) => [d.id, d.verified_status === 'verified'])
  );
  const cityFiltered = rows.filter((row) => {
    const ctx = resolveRouteContext(row);
    if (!ctx.routeId) return false;
    return true;
  });

  const routeIds = [...new Set(cityFiltered.map((r) => resolveRouteContext(r).routeId).filter(Boolean))];
  const { data: routeRows } = await supabase
    .from('routes')
    .select('id, city_id')
    .in('id', routeIds as string[]);

  const cityRouteIds = new Set(
    (routeRows ?? []).filter((r) => r.city_id === cityId).map((r) => r.id)
  );

  const mapped: FareCorrectionQueueRow[] = [];

  for (const row of cityFiltered) {
    const ctx = resolveRouteContext(row);
    if (!ctx.routeId || !cityRouteIds.has(ctx.routeId)) continue;

    const submitter = submitterLabel(row, riderTrust, driverVerified);
    const current = ctx.currentFare;
    const deltaPct =
      current != null && current !== 0
        ? ((row.proposed_fare - current) / current) * 100
        : null;

    const isMad = await loadMadFlag(
      supabase,
      ctx.routeId,
      ctx.fromStageId,
      row.proposed_fare,
      cityId
    );

    mapped.push({
      id: row.id,
      status: row.status,
      created_at: row.created_at,
      proposed_fare: row.proposed_fare,
      current_fare: current,
      fare_shown: row.fare_shown,
      currency: row.currency,
      delta_pct: deltaPct,
      submitter_role: row.submitter_role,
      submitter_trust: submitter.trust,
      submitter_label: submitter.label,
      trip_id: row.trip_id,
      is_mad_outlier: isMad,
      is_negotiation: row.submitter_role === 'system' && row.route_id != null && row.route_leg_id == null,
      route_label: ctx.routeLabel,
      stage_from: ctx.stageFrom,
      stage_to: ctx.stageTo,
      target_type: ctx.targetType,
      target_id: ctx.targetId,
    });
  }

  return sortCorrectionQueue(mapped);
}

export default async function CorrectionsPage({ params }: PageProps) {
  const { city: citySlug } = await params;
  const city = await getCityBySlug(citySlug);
  const queue = city ? await loadCorrectionsQueue(city.id) : [];
  const selectedId = queue.find((r) => r.status === 'pending')?.id ?? queue[0]?.id ?? null;

  return (
    <>
      <div className="page-header">
        <h1>Fare corrections</h1>
        <p>
          Proposed fare changes in <strong>{city?.name ?? citySlug}</strong>, with statistical outliers and negotiated fares flagged.
        </p>
      </div>
      {!city ? (
        <div className="error-banner" role="alert">
          City &quot;{citySlug}&quot; was not found in the database.
        </div>
      ) : null}
      <CorrectionsQueue
        citySlug={citySlug}
        initialRows={queue}
        initialSelectedId={selectedId}
      />
      {selectedId ? <AuditDrawer targetId={selectedId} targetLabel="fare correction" /> : null}
    </>
  );
}
