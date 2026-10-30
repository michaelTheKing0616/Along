"use client";

import Link from "next/link";
import { useState, useTransition } from "react";
import { formatMoney, maskPhone, standingLabel } from "@/lib/drivers/format";
import {
  evidenceBullets,
  flagTypeLabel,
  scorePct,
} from "@/lib/integrity/format";
import type { IntegrityFlagRow } from "@/lib/integrity/types";
import { STANDING_OPTIONS } from "@/lib/integrity/types";
import {
  notifyGuarantor,
  postManualAdjustment,
  rotateDriverCode,
  transitionDriverStanding,
} from "./actions";
import { humanize } from "@/lib/ui/label";
import {
  documentExpiry,
  type DriverDocumentCard,
  type DriverVehicleCard,
} from "@/lib/drivers/vehicle-docs";

export interface LedgerEntryRow {
  id: number;
  entry_type: string;
  amount: number;
  currency: string;
  balance_after: number;
  memo: string | null;
  created_at: string;
}

export interface StandingTransitionRow {
  id: number;
  from_standing: string | null;
  to_standing: string;
  reason: string;
  created_at: string;
}

export interface GuarantorRow {
  guarantor_name: string;
  guarantor_phone_e164: string;
  acknowledged_at: string | null;
  last_notified_at: string | null;
}

export interface DriverDetailData {
  id: string;
  display_name: string | null;
  phone_e164: string | null;
  city_name: string;
  verified_status: string;
  standing: string;
  rating: number | null;
  rating_count: number;
  driver_code: string | null;
  payout_subaccount_code: string | null;
  accepts_digital: boolean;
  balance: number;
  currency: string;
  ledger: LedgerEntryRow[];
  transitions: StandingTransitionRow[];
  flags: IntegrityFlagRow[];
  guarantor: GuarantorRow | null;
  vehicle: DriverVehicleCard | null;
  documents: DriverDocumentCard[];
  qrPayments: QrPaymentRow[];
  stickerRequests: StickerRequestRow[];
}

export interface QrPaymentRow {
  id: string;
  amount: number;
  currency: string;
  source: string;
  status: string;
  trip_id: string | null;
  created_at: string;
}

export interface StickerRequestRow {
  id: string;
  driver_code: string;
  reason: string;
  status: string;
  created_at: string;
}

type Tab =
  "overview" | "ledger" | "standing" | "flags" | "guarantor" | "payments";

interface DriverDetailProps {
  citySlug: string;
  driver: DriverDetailData;
}

export function DriverDetail({ citySlug, driver }: DriverDetailProps) {
  const [tab, setTab] = useState<Tab>("overview");
  const [amount, setAmount] = useState("");
  const [memo, setMemo] = useState("");
  const [toStanding, setToStanding] = useState<string>(
    STANDING_OPTIONS[0].value,
  );
  const [standingReason, setStandingReason] = useState("");
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [pending, startTransition] = useTransition();

  function runAction(
    action: () => Promise<{ ok: boolean; message?: string; error?: string }>,
  ) {
    setMessage(null);
    setError(null);
    startTransition(async () => {
      const result = await action();
      if (result.ok) setMessage(result.message ?? "Done.");
      else setError(result.error ?? "Action failed.");
    });
  }

  const tabs: { id: Tab; label: string }[] = [
    { id: "overview", label: "Overview" },
    { id: "ledger", label: "Ledger" },
    { id: "standing", label: "Standing" },
    { id: "flags", label: "Flags" },
    { id: "guarantor", label: "Guarantor" },
    { id: "payments", label: "Payments" },
  ];

  return (
    <div data-testid="driver-detail">
      <div className="kpi-grid" style={{ marginBottom: "var(--space-6)" }}>
        <div className="kpi">
          <p className="kpi-label">Balance</p>
          <p className="kpi-value">
            {formatMoney(driver.balance, driver.currency)}
          </p>
        </div>
        <div className="kpi">
          <p className="kpi-label">Rating</p>
          <p className="kpi-value">
            {driver.rating != null ? driver.rating.toFixed(2) : "—"}
          </p>
          <p className="kpi-sub">{driver.rating_count} ratings</p>
        </div>
        <div className="kpi">
          <p className="kpi-label">Standing</p>
          <p className="kpi-value kpi-sentence" style={{ fontSize: 18 }}>
            {standingLabel(driver.standing)}
          </p>
        </div>
        <div className="kpi">
          <p className="kpi-label">Verification</p>
          <p className="kpi-value" style={{ fontSize: 18 }}>
            <span className={`badge badge-${driver.verified_status}`}>
              {humanize(driver.verified_status)}
            </span>
          </p>
        </div>
        <Link
          href={`/${citySlug}/integrity`}
          className={`kpi kpi-link${driver.flags.filter((f) => f.status === "open").length > 0 ? " kpi-hot" : ""}`}
        >
          <p className="kpi-label">Open flags</p>
          <p className="kpi-value">
            {driver.flags.filter((f) => f.status === "open").length}
          </p>
        </Link>
      </div>

      {error ? (
        <div className="error-banner" role="alert" data-testid="driver-error">
          {error}
        </div>
      ) : null}
      {message ? (
        <div
          className="card"
          role="status"
          data-testid="driver-success"
          style={{ marginBottom: "var(--space-4)" }}
        >
          {message}
        </div>
      ) : null}

      <div
        className="seg"
        role="tablist"
        aria-label="Driver sections"
        style={{ marginBottom: "var(--space-4)" }}
      >
        {tabs.map(({ id, label }) => (
          <button
            key={id}
            type="button"
            role="tab"
            aria-selected={tab === id}
            className={tab === id ? "nav-link-active" : undefined}
            data-testid={`driver-tab-${id}`}
            onClick={() => setTab(id)}
          >
            {label}
          </button>
        ))}
      </div>

      {tab === "overview" ? (
        <div className="overview-grid" data-testid="driver-overview">
          <section className="card">
            <h2 className="section-title">Profile</h2>
            <dl className="dl">
              <dt>Driver code</dt>
              <dd>{driver.driver_code ?? "—"}</dd>
              <dt>Rating</dt>
              <dd>
                {driver.rating != null
                  ? `${driver.rating.toFixed(2)} (${driver.rating_count})`
                  : "—"}
              </dd>
              <dt>Phone</dt>
              <dd>{maskPhone(driver.phone_e164)}</dd>
              <dt>City</dt>
              <dd>{driver.city_name}</dd>
              <dt>Payout account</dt>
              <dd>{driver.payout_subaccount_code ? "Linked" : "Not linked"}</dd>
              <dt>Digital pay</dt>
              <dd>{driver.accepts_digital ? "Accepts QR" : "Cash only"}</dd>
            </dl>
          </section>
          <section className="card" data-testid="driver-vehicle">
            <h2 className="section-title">Vehicle</h2>
            {driver.vehicle ? (
              <dl className="dl">
                <dt>Plate</dt>
                <dd className="mono">{driver.vehicle.plate_number}</dd>
                <dt>Vehicle</dt>
                <dd>
                  {[driver.vehicle.color, driver.vehicle.make_model]
                    .filter(Boolean)
                    .join(" ") || "—"}
                </dd>
                <dt>Mode · seats</dt>
                <dd>
                  {humanize(driver.vehicle.mode_code).replace(/^./, (c) =>
                    c.toUpperCase(),
                  )}{" "}
                  · {driver.vehicle.seat_capacity}
                </dd>
                <dt>Verification</dt>
                <dd>
                  <span
                    className={`badge badge-${driver.vehicle.verification_status === "verified" ? "approved" : driver.vehicle.verification_status}`}
                  >
                    {humanize(driver.vehicle.verification_status)}
                  </span>
                </dd>
                <dt>Driving since</dt>
                <dd>{new Date(driver.vehicle.since).toLocaleDateString()}</dd>
              </dl>
            ) : (
              <p className="empty-inline">No active vehicle linked.</p>
            )}
          </section>
          <section className="card" data-testid="driver-documents">
            <h2 className="section-title">Documents</h2>
            {driver.documents.length === 0 ? (
              <p className="empty-inline">
                No documents visible. Verifiers and ops leads can see uploads.
              </p>
            ) : (
              <ul className="mini-list">
                {driver.documents.map((d) => {
                  const exp = documentExpiry(d.expires_at);
                  return (
                    <li key={d.id}>
                      <span>
                        <span
                          className="kpi-sentence"
                          style={{ display: "block" }}
                        >
                          {humanize(d.document_type)}
                        </span>
                        <span className="cell-sub">
                          {d.rejection_reason
                            ? d.rejection_reason
                            : d.expires_at
                              ? `${exp === "expired" ? "Expired" : "Expires"} ${new Date(d.expires_at).toLocaleDateString()}`
                              : `Submitted ${new Date(d.submitted_at).toLocaleDateString()}`}
                        </span>
                      </span>
                      <span
                        className={`badge badge-${exp === "expired" ? "rejected" : exp === "soon" ? "acknowledged" : d.status}`}
                      >
                        {exp === "expired"
                          ? "Expired"
                          : exp === "soon"
                            ? "Expiring"
                            : humanize(d.status)}
                      </span>
                    </li>
                  );
                })}
              </ul>
            )}
          </section>
          <section className="card">
            <h2 className="section-title">Recent paid trips</h2>
            {driver.qrPayments.length === 0 ? (
              <p className="empty-inline">No digital payments yet.</p>
            ) : (
              <ul className="mini-list">
                {driver.qrPayments.slice(0, 4).map((p) => (
                  <li key={p.id}>
                    <span>
                      {new Date(p.created_at).toLocaleDateString()}
                      <span className="cell-sub">
                        {humanize(p.source)} · {humanize(p.status)}
                      </span>
                    </span>
                    <span className="num">
                      {formatMoney(p.amount, p.currency)}
                    </span>
                  </li>
                ))}
              </ul>
            )}
          </section>
          <section className="card">
            <h2 className="section-title">Standing history</h2>
            {driver.transitions.length === 0 ? (
              <p className="empty-inline">No standing changes.</p>
            ) : (
              <ul className="mini-list">
                {driver.transitions.slice(0, 4).map((t) => (
                  <li key={t.id}>
                    <span>
                      <span
                        className="kpi-sentence"
                        style={{ display: "block" }}
                      >
                        {standingLabel(t.to_standing)}
                      </span>
                      <span className="cell-sub">{t.reason}</span>
                    </span>
                    <span className="cell-sub">
                      {new Date(t.created_at).toLocaleDateString()}
                    </span>
                  </li>
                ))}
              </ul>
            )}
          </section>
          <section className="card">
            <h2 className="section-title">Guarantor</h2>
            {driver.guarantor ? (
              <dl className="dl">
                <dt>Name</dt>
                <dd>{driver.guarantor.guarantor_name}</dd>
                <dt>Acknowledged</dt>
                <dd>
                  {driver.guarantor.acknowledged_at
                    ? new Date(
                        driver.guarantor.acknowledged_at,
                      ).toLocaleDateString()
                    : "Not yet"}
                </dd>
              </dl>
            ) : (
              <p className="empty-inline">No guarantor on file.</p>
            )}
          </section>
        </div>
      ) : null}

      {tab === "ledger" ? (
        <div data-testid="driver-ledger">
          <table
            className="data-table"
            style={{ marginBottom: "var(--space-6)" }}
          >
            <thead>
              <tr>
                <th>Date</th>
                <th>Type</th>
                <th className="num">Amount</th>
                <th className="num">Balance</th>
                <th>Memo</th>
              </tr>
            </thead>
            <tbody>
              {driver.ledger.map((entry) => (
                <tr key={entry.id}>
                  <td>{new Date(entry.created_at).toLocaleString()}</td>
                  <td>{entry.entry_type}</td>
                  <td className="num">
                    {formatMoney(entry.amount, entry.currency)}
                  </td>
                  <td className="num">
                    {formatMoney(entry.balance_after, entry.currency)}
                  </td>
                  <td>{entry.memo ?? "—"}</td>
                </tr>
              ))}
            </tbody>
          </table>

          <div className="card">
            <h3 className="sub-title">Manual adjustment</h3>
            <div className="field">
              <label htmlFor="adj-amount">Amount (₦)</label>
              <input
                id="adj-amount"
                type="number"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                data-testid="adjustment-amount"
              />
            </div>
            <div className="field">
              <label htmlFor="adj-memo">Memo</label>
              <input
                id="adj-memo"
                value={memo}
                onChange={(e) => setMemo(e.target.value)}
                data-testid="adjustment-memo"
              />
            </div>
            <button
              type="button"
              className="btn btn-primary"
              disabled={pending || !amount || !memo.trim()}
              data-testid="submit-adjustment"
              onClick={() =>
                runAction(() =>
                  postManualAdjustment(
                    citySlug,
                    driver.id,
                    Number(amount),
                    memo,
                  ),
                )
              }
            >
              Submit adjustment
            </button>
          </div>
        </div>
      ) : null}

      {tab === "standing" ? (
        <div data-testid="driver-standing">
          <table
            className="data-table"
            style={{ marginBottom: "var(--space-6)" }}
          >
            <thead>
              <tr>
                <th>Date</th>
                <th>From</th>
                <th>To</th>
                <th>Reason</th>
              </tr>
            </thead>
            <tbody>
              {driver.transitions.map((row) => (
                <tr key={row.id}>
                  <td>{new Date(row.created_at).toLocaleString()}</td>
                  <td>
                    {row.from_standing ? standingLabel(row.from_standing) : "—"}
                  </td>
                  <td>{standingLabel(row.to_standing)}</td>
                  <td>{row.reason}</td>
                </tr>
              ))}
            </tbody>
          </table>

          <div className="card">
            <h3 className="sub-title">Transition standing</h3>
            <div className="field">
              <label htmlFor="driver-standing-to">To</label>
              <select
                id="driver-standing-to"
                value={toStanding}
                onChange={(e) => setToStanding(e.target.value)}
                data-testid="driver-standing-to"
              >
                {STANDING_OPTIONS.map((opt) => (
                  <option key={opt.value} value={opt.value}>
                    {opt.label}
                  </option>
                ))}
              </select>
            </div>
            <div className="field">
              <label htmlFor="driver-standing-reason">Reason</label>
              <textarea
                id="driver-standing-reason"
                rows={3}
                value={standingReason}
                onChange={(e) => setStandingReason(e.target.value)}
                data-testid="driver-standing-reason"
              />
            </div>
            <button
              type="button"
              className="btn btn-primary"
              disabled={pending || !standingReason.trim()}
              data-testid="submit-standing"
              onClick={() =>
                runAction(() =>
                  transitionDriverStanding(
                    citySlug,
                    driver.id,
                    toStanding,
                    standingReason,
                  ),
                )
              }
            >
              Apply transition
            </button>
          </div>
        </div>
      ) : null}

      {tab === "flags" ? (
        <div data-testid="driver-flags">
          {driver.flags.length === 0 ? (
            <p className="empty-inline">No reconciliation flags.</p>
          ) : (
            driver.flags.map((flag) => (
              <div
                key={flag.id}
                className="card"
                style={{ marginBottom: "var(--space-3)" }}
              >
                <strong>{flagTypeLabel(flag.flag_type)}</strong> ·{" "}
                {scorePct(flag.score)} ·{" "}
                <span className={`badge badge-${flag.status}`}>
                  {humanize(flag.status)}
                </span>
                <ul style={{ fontSize: "0.875rem", marginBottom: 0 }}>
                  {evidenceBullets(flag.evidence).map((item) => (
                    <li key={item}>{item}</li>
                  ))}
                </ul>
              </div>
            ))
          )}
        </div>
      ) : null}

      {tab === "guarantor" ? (
        <div className="card" data-testid="driver-guarantor">
          {driver.guarantor ? (
            <>
              <p>
                <strong>{driver.guarantor.guarantor_name}</strong> ·{" "}
                {maskPhone(driver.guarantor.guarantor_phone_e164)}
              </p>
              <p
                style={{
                  fontSize: "0.875rem",
                  color: "var(--color-text-muted)",
                }}
              >
                Acknowledged:{" "}
                {driver.guarantor.acknowledged_at
                  ? new Date(driver.guarantor.acknowledged_at).toLocaleString()
                  : "Pending"}
                · Last notified:{" "}
                {driver.guarantor.last_notified_at
                  ? new Date(driver.guarantor.last_notified_at).toLocaleString()
                  : "Never"}
              </p>
              <button
                type="button"
                className="btn btn-primary"
                disabled={pending}
                data-testid="notify-guarantor"
                onClick={() =>
                  runAction(() => notifyGuarantor(citySlug, driver.id))
                }
              >
                Notify guarantor
              </button>
            </>
          ) : (
            <p className="empty-inline">No guarantor on file.</p>
          )}
        </div>
      ) : null}

      {tab === "payments" ? (
        <div data-testid="driver-payments">
          <dl
            className="card"
            style={{
              margin: 0,
              marginBottom: "var(--space-4)",
              display: "grid",
              gridTemplateColumns: "max-content 1fr",
              gap: "var(--space-2) var(--space-4)",
              fontSize: "0.875rem",
            }}
          >
            <dt>Driver code</dt>
            <dd data-testid="driver-payments-code">
              {driver.driver_code ?? "—"}
            </dd>
            <dt>Subaccount</dt>
            <dd data-testid="driver-payments-subaccount">
              {driver.payout_subaccount_code ? "Active" : "Not configured"}
            </dd>
            <dt>Digital acceptance</dt>
            <dd data-testid="driver-payments-digital">
              {driver.accepts_digital && driver.payout_subaccount_code
                ? "Accepting QR / digital"
                : "Cash only / paused"}
            </dd>
          </dl>

          <div className="card" style={{ marginBottom: "var(--space-4)" }}>
            <h3 className="sub-title">Rotate code</h3>
            <p
              style={{ fontSize: "0.875rem", color: "var(--color-text-muted)" }}
            >
              Invalidates printed stickers and creates a reprint request.
            </p>
            <button
              type="button"
              className="btn btn-primary"
              disabled={pending || !driver.driver_code}
              data-testid="rotate-driver-code"
              onClick={() =>
                runAction(() => rotateDriverCode(citySlug, driver.id))
              }
            >
              Rotate driver code
            </button>
          </div>

          <section style={{ marginBottom: "var(--space-6)" }}>
            <h3>QR payments received</h3>
            {driver.qrPayments.length === 0 ? (
              <p className="empty-inline">No QR payments yet.</p>
            ) : (
              <table className="data-table" data-testid="driver-qr-payments">
                <thead>
                  <tr>
                    <th>Date</th>
                    <th className="num">Amount</th>
                    <th>Source</th>
                    <th>Status</th>
                    <th>Trip</th>
                  </tr>
                </thead>
                <tbody>
                  {driver.qrPayments.map((row) => (
                    <tr key={row.id}>
                      <td>{new Date(row.created_at).toLocaleString()}</td>
                      <td className="num">
                        {formatMoney(row.amount, row.currency)}
                      </td>
                      <td>{row.source}</td>
                      <td>{row.status}</td>
                      <td>{row.trip_id ? "Attributed" : "Unattributed"}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </section>

          <section>
            <h3>Sticker requests</h3>
            {driver.stickerRequests.length === 0 ? (
              <p className="empty-inline">No sticker requests.</p>
            ) : (
              <table
                className="data-table"
                data-testid="driver-sticker-requests"
              >
                <thead>
                  <tr>
                    <th>Date</th>
                    <th>Code</th>
                    <th>Reason</th>
                    <th>Status</th>
                  </tr>
                </thead>
                <tbody>
                  {driver.stickerRequests.map((row) => (
                    <tr key={row.id}>
                      <td>{new Date(row.created_at).toLocaleString()}</td>
                      <td>{row.driver_code}</td>
                      <td>{row.reason}</td>
                      <td>{row.status}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </section>
        </div>
      ) : null}
    </div>
  );
}
