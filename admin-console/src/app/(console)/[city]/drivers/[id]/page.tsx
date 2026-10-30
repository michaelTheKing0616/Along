import { getCityBySlug } from "@/lib/city/resolve";
import type { IntegrityFlagRow } from "@/lib/integrity/types";
import { createClient } from "@/lib/supabase/server";
import { DriverDetail, type DriverDetailData } from "./driver-detail";

interface PageProps {
  params: Promise<{ city: string; id: string }>;
}

export default async function DriverDetailPage({ params }: PageProps) {
  const { city: citySlug, id: driverId } = await params;
  const city = await getCityBySlug(citySlug);
  const supabase = await createClient();

  if (!city) {
    return (
      <>
        <div className="page-header">
          <h1>Driver</h1>
        </div>
        <div className="error-banner" role="alert">
          City &quot;{citySlug}&quot; was not found.
        </div>
      </>
    );
  }

  const { data: driverRow, error } = await supabase
    .from("drivers")
    .select(
      `
      id,
      verified_status,
      standing,
      rating,
      rating_count,
      driver_code,
      payout_subaccount_code,
      accepts_digital,
      city_id,
      profiles!drivers_id_fkey ( display_name, phone_e164 )
    `,
    )
    .eq("id", driverId)
    .eq("city_id", city.id)
    .maybeSingle();

  if (error || !driverRow) {
    return (
      <>
        <div className="page-header">
          <h1>Driver not found</h1>
        </div>
        <p className="empty-inline">
          No driver in this city with id {driverId}.
        </p>
      </>
    );
  }

  const profile = driverRow.profiles as {
    display_name: string | null;
    phone_e164: string | null;
  } | null;

  const [
    { data: balanceRow },
    { data: ledgerRows },
    { data: transitionRows },
    { data: flagRows },
    { data: guarantorRows },
    { data: paymentRows },
    { data: stickerRows },
  ] = await Promise.all([
    supabase
      .from("driver_balances")
      .select("balance")
      .eq("driver_id", driverId)
      .maybeSingle(),
    supabase
      .from("driver_ledger_entries")
      .select(
        "id, entry_type, amount, currency, balance_after, memo, created_at",
      )
      .eq("driver_id", driverId)
      .order("created_at", { ascending: false })
      .limit(50),
    supabase
      .from("driver_standing_transitions")
      .select("id, from_standing, to_standing, reason, created_at")
      .eq("driver_id", driverId)
      .order("created_at", { ascending: false })
      .limit(20),
    supabase
      .from("trip_reconciliation_flags")
      .select(
        "id, trip_id, driver_id, flag_type, score, evidence, rider_trace_quality, corroborating_rider_count, status, created_at",
      )
      .eq("driver_id", driverId)
      .order("score", { ascending: false }),
    supabase
      .from("guarantors")
      .select(
        "guarantor_name, guarantor_phone_e164, acknowledged_at, last_notified_at",
      )
      .eq("driver_id", driverId)
      .order("created_at", { ascending: false })
      .limit(1),
    supabase
      .from("payments")
      .select("id, amount, currency, source, status, trip_id, created_at")
      .eq("driver_id", driverId)
      .in("source", ["qr_static", "qr_dynamic", "web_anonymous"])
      .order("created_at", { ascending: false })
      .limit(50),
    supabase
      .from("qr_sticker_requests")
      .select("id, driver_code, reason, status, created_at")
      .eq("driver_id", driverId)
      .order("created_at", { ascending: false })
      .limit(20),
  ]);

  const flags: IntegrityFlagRow[] = (flagRows ?? []).map((row) => ({
    id: row.id,
    trip_id: row.trip_id,
    driver_id: row.driver_id,
    driver_name: profile?.display_name ?? null,
    driver_code: driverRow.driver_code,
    flag_type: row.flag_type as IntegrityFlagRow["flag_type"],
    score: Number(row.score),
    evidence: (row.evidence as Record<string, unknown>) ?? {},
    rider_trace_quality: row.rider_trace_quality,
    corroborating_rider_count: row.corroborating_rider_count,
    status: row.status as IntegrityFlagRow["status"],
    created_at: row.created_at,
    risk_cancel_rate: null,
    risk_open_flags: null,
  }));

  const driver: DriverDetailData = {
    id: driverRow.id,
    display_name: profile?.display_name ?? null,
    phone_e164: profile?.phone_e164 ?? null,
    city_name: city.name,
    verified_status: driverRow.verified_status,
    standing: driverRow.standing,
    rating: driverRow.rating != null ? Number(driverRow.rating) : null,
    rating_count: driverRow.rating_count,
    driver_code: driverRow.driver_code,
    payout_subaccount_code: driverRow.payout_subaccount_code,
    accepts_digital: driverRow.accepts_digital,
    balance: Number(balanceRow?.balance ?? 0),
    currency: "NGN",
    ledger: (ledgerRows ?? []).map((e) => ({
      id: e.id,
      entry_type: e.entry_type,
      amount: Number(e.amount),
      currency: e.currency,
      balance_after: Number(e.balance_after),
      memo: e.memo,
      created_at: e.created_at,
    })),
    transitions: (transitionRows ?? []).map((t) => ({
      id: t.id,
      from_standing: t.from_standing,
      to_standing: t.to_standing,
      reason: t.reason,
      created_at: t.created_at,
    })),
    flags,
    guarantor: guarantorRows?.[0] ?? null,
    qrPayments: (paymentRows ?? []).map((p) => ({
      id: p.id,
      amount: Number(p.amount),
      currency: p.currency,
      source: p.source,
      status: p.status,
      trip_id: p.trip_id,
      created_at: p.created_at,
    })),
    stickerRequests: (stickerRows ?? []).map((s) => ({
      id: s.id,
      driver_code: s.driver_code,
      reason: s.reason,
      status: s.status,
      created_at: s.created_at,
    })),
  };

  return (
    <>
      <div className="page-header">
        <h1>Driver detail</h1>
        <p>
          {profile?.display_name ?? "Unnamed driver"}
          {driverRow.driver_code ? ` · ${driverRow.driver_code}` : ""}
        </p>
      </div>
      <DriverDetail citySlug={citySlug} driver={driver} />
    </>
  );
}
