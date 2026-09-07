import { ConsoleNav } from '@/components/along/ConsoleNav';
import type {
  CorporateAllocationRow,
  CorporateInvoiceRow,
  CorporateMemberRow,
  CorporateOverview,
  CorporatePolicyRow,
} from '@/lib/corporate/types';
import { getCityBySlug } from '@/lib/city/resolve';
import { checkAdminRole, createClient } from '@/lib/supabase/server';
import { fromUntyped, rpcUntyped } from '@/lib/supabase/untyped';
import { CorporateConsole } from './corporate-console';

interface PageProps {
  params: Promise<{ city: string }>;
}

async function loadCorporatePortal() {
  const supabase = await createClient();
  const isCorporateAdmin = await checkAdminRole(['corporate_admin']);

  if (!isCorporateAdmin) {
    return {
      isCorporateAdmin: false,
      overview: null,
      members: [] as CorporateMemberRow[],
      policies: [] as CorporatePolicyRow[],
      allocations: [] as CorporateAllocationRow[],
      invoices: [] as CorporateInvoiceRow[],
      invoiceLinesByInvoice: {} as Record<string, Array<{ allocation_id: string; amount: number }>>,
    };
  }

  const { data: overviewData } = await rpcUntyped(supabase, 'corporate_overview');
  const overview = (overviewData ?? null) as CorporateOverview | null;

  const { data: memberRows } = await fromUntyped(supabase, 'corporate_members')
    .select(
      'rider_id, employee_ref, department, default_policy_id, active, since, profiles ( phone_e164, display_name ), corporate_trip_policies ( name )'
    )
    .order('since', { ascending: false });

  const members: CorporateMemberRow[] = ((memberRows ?? []) as Array<Record<string, unknown>>).map(
    (row) => {
      const profile = row.profiles as { phone_e164?: string; display_name?: string } | null;
      const policy = row.corporate_trip_policies as { name?: string } | null;
      return {
        rider_id: String(row.rider_id),
        employee_ref: (row.employee_ref as string | null) ?? null,
        department: (row.department as string | null) ?? null,
        default_policy_id: (row.default_policy_id as string | null) ?? null,
        active: Boolean(row.active),
        since: String(row.since),
        phone_e164: profile?.phone_e164 ?? null,
        display_name: profile?.display_name ?? null,
        policy_name: policy?.name ?? null,
      };
    }
  );

  const { data: policyRows } = await fromUntyped(supabase, 'corporate_trip_policies')
    .select('id, name, subsidy_pct, max_per_trip, allowed_hours, active')
    .order('created_at', { ascending: false });

  const policies = ((policyRows ?? []) as Array<Record<string, unknown>>).map((row) => ({
    id: String(row.id),
    name: String(row.name),
    subsidy_pct: Number(row.subsidy_pct),
    max_per_trip: row.max_per_trip != null ? Number(row.max_per_trip) : null,
    allowed_hours: (row.allowed_hours as Record<string, unknown> | null) ?? null,
    active: Boolean(row.active),
  }));

  const { data: allocationRows } = await fromUntyped(supabase, 'corporate_trip_allocations')
    .select(
      'id, trip_id, subsidized_amount, created_at, corporate_trip_policies ( name ), trips ( mode_code, fare_shown, rider_id )'
    )
    .order('created_at', { ascending: false })
    .limit(200);

  const riderIds = new Set<string>();
  for (const row of allocationRows ?? []) {
    const trip = (row as Record<string, unknown>).trips as { rider_id?: string } | null;
    if (trip?.rider_id) riderIds.add(trip.rider_id);
  }

  const memberByRider = new Map(members.map((m) => [m.rider_id, m]));

  const allocations: CorporateAllocationRow[] = ((allocationRows ?? []) as Array<
    Record<string, unknown>
  >).map((row) => {
    const trip = row.trips as { mode_code?: string; fare_shown?: number; rider_id?: string } | null;
    const policy = row.corporate_trip_policies as { name?: string } | null;
    const riderId = trip?.rider_id;
    const member = riderId ? memberByRider.get(riderId) : undefined;
    return {
      id: String(row.id),
      trip_id: String(row.trip_id),
      subsidized_amount: Number(row.subsidized_amount),
      created_at: String(row.created_at),
      employee_ref: member?.employee_ref ?? null,
      department: member?.department ?? null,
      mode_code: trip?.mode_code ?? null,
      fare_shown: trip?.fare_shown != null ? Number(trip.fare_shown) : null,
      policy_name: policy?.name ?? null,
    };
  });

  const { data: invoiceRows } = await fromUntyped(supabase, 'corporate_invoices')
    .select('id, period_start, period_end, total, currency, status, generated_at')
    .order('generated_at', { ascending: false });

  const invoices: CorporateInvoiceRow[] = ((invoiceRows ?? []) as Array<Record<string, unknown>>).map(
    (row) => ({
      id: String(row.id),
      period_start: String(row.period_start),
      period_end: String(row.period_end),
      total: Number(row.total),
      currency: String(row.currency),
      status: String(row.status),
      generated_at: String(row.generated_at),
    })
  );

  const invoiceIds = invoices.map((i) => i.id);
  const invoiceLinesByInvoice: Record<string, Array<{ allocation_id: string; amount: number }>> = {};

  if (invoiceIds.length > 0) {
    const { data: lineRows } = await fromUntyped(supabase, 'invoice_lines')
      .select('invoice_id, allocation_id, amount')
      .in('invoice_id', invoiceIds);

    for (const line of (lineRows ?? []) as Array<Record<string, unknown>>) {
      const invoiceId = String(line.invoice_id);
      if (!invoiceLinesByInvoice[invoiceId]) invoiceLinesByInvoice[invoiceId] = [];
      invoiceLinesByInvoice[invoiceId].push({
        allocation_id: String(line.allocation_id),
        amount: Number(line.amount),
      });
    }
  }

  return {
    isCorporateAdmin: true,
    overview,
    members,
    policies,
    allocations,
    invoices,
    invoiceLinesByInvoice,
  };
}

export default async function CorporatePage({ params }: PageProps) {
  const { city: citySlug } = await params;
  const city = await getCityBySlug(citySlug);
  const portal = await loadCorporatePortal();

  return (
    <>
      <div className="page-header">
        <h1>Corporate portal</h1>
        <p>
          Staff roster, trip policies, subsidized trip history, and billing for{' '}
          <strong>{city?.name ?? citySlug}</strong>.
        </p>
      </div>
      {!city ? (
        <div className="error-banner" role="alert">
          City &quot;{citySlug}&quot; was not found in the database.
        </div>
      ) : null}
      <ConsoleNav city={citySlug} />
      <CorporateConsole citySlug={citySlug} {...portal} />
    </>
  );
}
