import { getCityBySlug } from '@/lib/city/resolve';
import type {
  FeeBearerReport,
  PendingAdjustmentRow,
  PayoutRow,
  QrPaymentFinanceRow,
  SettlementAgentRow,
  SettlementRow,
  StickerBatchDriver,
} from '@/lib/finance/types';
import { createClient } from '@/lib/supabase/server';
import { FinanceConsole } from './finance-console';

interface PageProps {
  params: Promise<{ city: string }>;
}

async function loadFinanceData(cityId: string) {
  const supabase = await createClient();

  const { data: driverRows } = await supabase
    .from('drivers')
    .select('id, driver_code')
    .eq('city_id', cityId);

  const driverIds = (driverRows ?? []).map((d) => d.id);
  const driverCodeById = new Map(
    (driverRows ?? []).map((d) => [d.id, d.driver_code])
  );

  if (driverIds.length === 0) {
    return {
      settlements: [] as SettlementRow[],
      agents: [] as SettlementAgentRow[],
      pendingAdjustments: [] as PendingAdjustmentRow[],
      payouts: [] as PayoutRow[],
      qrPayments: [] as QrPaymentFinanceRow[],
      feeBearerReport: null as FeeBearerReport | null,
      stickerDrivers: [] as StickerBatchDriver[],
    };
  }

  const [
    { data: settlementRows },
    { data: agentRows },
    { data: pendingRows },
    { data: payoutRows },
    { data: qrPaymentRows },
    { data: feeBearerConfig },
  ] = await Promise.all([
    supabase
      .from('settlements')
      .select('id, driver_id, amount, currency, channel, status, created_at, confirmed_at')
      .in('driver_id', driverIds)
      .order('created_at', { ascending: false })
      .limit(100),
    supabase
      .from('settlement_agents')
      .select('id, business_name, active, created_at, profile_id, profiles ( phone_e164 )')
      .eq('city_id', cityId)
      .order('created_at', { ascending: false }),
    supabase
      .from('pending_ledger_adjustments')
      .select('id, driver_id, amount, currency, memo, requested_by, created_at')
      .eq('status', 'pending')
      .in('driver_id', driverIds)
      .order('created_at', { ascending: true }),
    supabase
      .from('driver_payouts')
      .select('id, driver_id, amount, currency, status, provider_reference, created_at, confirmed_at')
      .in('driver_id', driverIds)
      .order('created_at', { ascending: false })
      .limit(50),
    supabase
      .from('payments')
      .select(
        'id, driver_id, amount, currency, source, status, trip_id, commission_amount, provider_fee, fee_bearer, created_at'
      )
      .in('driver_id', driverIds)
      .in('source', ['qr_static', 'qr_dynamic', 'web_anonymous'])
      .order('created_at', { ascending: false })
      .limit(100),
    supabase.rpc('cfg', { p_key: 'payments.fee_bearer', p_city: cityId }),
  ]);

  const requesterIds = [...new Set((pendingRows ?? []).map((r) => r.requested_by))];
  const { data: requesterProfiles } = await supabase
    .from('profiles')
    .select('id, display_name')
    .in('id', requesterIds);

  const requesterName = new Map(
    (requesterProfiles ?? []).map((p) => [p.id, p.display_name])
  );

  const qrPayments = (qrPaymentRows ?? []).map((row) => ({
    id: row.id,
    driver_id: row.driver_id,
    driver_code: driverCodeById.get(row.driver_id) ?? null,
    amount: Number(row.amount),
    currency: row.currency,
    source: row.source,
    status: row.status,
    trip_id: row.trip_id,
    commission_amount: Number(row.commission_amount),
    provider_fee: row.provider_fee != null ? Number(row.provider_fee) : null,
    fee_bearer: row.fee_bearer,
    created_at: row.created_at,
  }));

  const succeededQr = qrPayments.filter((p) => p.status === 'succeeded');
  const feeBearerReport: FeeBearerReport = {
    fee_bearer: String(feeBearerConfig ?? 'account').replace(/^"|"$/g, ''),
    payment_count: succeededQr.length,
    commission_total: succeededQr.reduce((sum, p) => sum + p.commission_amount, 0),
    provider_fee_total: succeededQr.reduce((sum, p) => sum + (p.provider_fee ?? 0), 0),
  };

  const { data: stickerDriverRows } = await supabase
    .from('drivers')
    .select(
      `
      id,
      driver_code,
      driver_vehicles (
        active,
        vehicles ( plate_number )
      )
    `
    )
    .eq('city_id', cityId)
    .not('driver_code', 'is', null)
    .order('driver_code');

  const origin =
    process.env.NEXT_PUBLIC_PAY_ORIGIN ??
    process.env.NEXT_PUBLIC_SITE_URL ??
    'http://127.0.0.1:3000';

  const stickerDrivers: StickerBatchDriver[] = (stickerDriverRows ?? [])
    .filter((d) => d.driver_code)
    .map((d) => {
      const dv = d.driver_vehicles as Array<{
        active: boolean;
        vehicles: { plate_number: string } | null;
      }>;
      const plate = dv?.find((v) => v.active)?.vehicles?.plate_number ?? null;
      const code = d.driver_code as string;
      return {
        id: d.id,
        driver_code: code,
        plate,
        pay_url: `${origin.replace(/\/$/, '')}/p/${code}`,
      };
    });

  return {
    settlements: (settlementRows ?? []).map((row) => ({
      id: row.id,
      driver_id: row.driver_id,
      driver_code: driverCodeById.get(row.driver_id) ?? null,
      amount: Number(row.amount),
      currency: row.currency,
      channel: row.channel,
      status: row.status,
      created_at: row.created_at,
      confirmed_at: row.confirmed_at,
    })),
    agents: (agentRows ?? []).map((row) => ({
      id: row.id,
      business_name: row.business_name,
      phone: (row.profiles as { phone_e164: string | null } | null)?.phone_e164 ?? null,
      active: row.active,
      created_at: row.created_at,
    })),
    pendingAdjustments: (pendingRows ?? []).map((row) => ({
      id: row.id,
      driver_id: row.driver_id,
      driver_code: driverCodeById.get(row.driver_id) ?? null,
      amount: Number(row.amount),
      currency: row.currency,
      memo: row.memo,
      requested_by: row.requested_by,
      requested_by_name: requesterName.get(row.requested_by) ?? null,
      created_at: row.created_at,
    })),
    payouts: (payoutRows ?? []).map((row) => ({
      id: row.id,
      driver_id: row.driver_id,
      driver_code: driverCodeById.get(row.driver_id) ?? null,
      amount: Number(row.amount),
      currency: row.currency,
      status: row.status,
      provider_reference: row.provider_reference,
      created_at: row.created_at,
      confirmed_at: row.confirmed_at,
    })),
    qrPayments,
    feeBearerReport,
    stickerDrivers,
  };
}

export default async function FinancePage({ params }: PageProps) {
  const { city: citySlug } = await params;
  const city = await getCityBySlug(citySlug);
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  const data = city ? await loadFinanceData(city.id) : null;

  return (
    <>
      <div className="page-header">
        <h1>Finance</h1>
        <p>
          Settlements, cash agents, two-person adjustments, and payouts in <strong>{city?.name ?? citySlug}</strong>.
        </p>
      </div>
      {!city ? (
        <div className="error-banner" role="alert">
          City &quot;{citySlug}&quot; was not found in the database.
        </div>
      ) : null}
      {city && data ? (
        <FinanceConsole
          citySlug={citySlug}
          cityId={city.id}
          settlements={data.settlements}
          agents={data.agents}
          pendingAdjustments={data.pendingAdjustments}
          payouts={data.payouts}
          qrPayments={data.qrPayments}
          feeBearerReport={data.feeBearerReport}
          stickerDrivers={data.stickerDrivers}
          currentAdminId={user?.id ?? null}
        />
      ) : null}
    </>
  );
}
