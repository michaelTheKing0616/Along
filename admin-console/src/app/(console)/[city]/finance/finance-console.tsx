'use client';

import Link from 'next/link';
import { useState, useTransition } from 'react';
import { formatMoney } from '@/lib/drivers/format';
import type {
  FeeBearerReport,
  PendingAdjustmentRow,
  PayoutRow,
  QrPaymentFinanceRow,
  SettlementAgentRow,
  SettlementRow,
  StickerBatchDriver,
} from '@/lib/finance/types';
import { approvePendingAdjustment, upsertSettlementAgent } from './actions';
import { humanize } from '@/lib/ui/label';

interface FinanceConsoleProps {
  citySlug: string;
  cityId: string;
  settlements: SettlementRow[];
  agents: SettlementAgentRow[];
  pendingAdjustments: PendingAdjustmentRow[];
  payouts: PayoutRow[];
  qrPayments: QrPaymentFinanceRow[];
  feeBearerReport: FeeBearerReport | null;
  stickerDrivers: StickerBatchDriver[];
  currentAdminId: string | null;
}

export function FinanceConsole({
  citySlug,
  cityId,
  settlements,
  agents,
  pendingAdjustments,
  payouts,
  qrPayments,
  feeBearerReport,
  stickerDrivers,
  currentAdminId,
}: FinanceConsoleProps) {
  const [businessName, setBusinessName] = useState('');
  const [phone, setPhone] = useState('');
  const [selectedStickerDrivers, setSelectedStickerDrivers] = useState<Set<string>>(new Set());
  const [exportingPdf, setExportingPdf] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [pending, startTransition] = useTransition();

  function runAction(action: () => Promise<{ ok: boolean; message?: string; error?: string }>) {
    setMessage(null);
    setError(null);
    startTransition(async () => {
      const result = await action();
      if (result.ok) {
        setMessage(result.message ?? 'Done.');
        setBusinessName('');
        setPhone('');
      } else {
        setError(result.error ?? 'Action failed.');
      }
    });
  }

  function toggleStickerDriver(id: string) {
    setSelectedStickerDrivers((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  }

  async function exportStickerBatch() {
    setMessage(null);
    setError(null);
    if (selectedStickerDrivers.size === 0) {
      setError('Select at least one driver.');
      return;
    }
    setExportingPdf(true);
    try {
      const res = await fetch('/api/finance/sticker-batch', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          cityId,
          driverIds: [...selectedStickerDrivers],
        }),
      });
      if (!res.ok) {
        const body = (await res.json()) as { error?: string };
        throw new Error(body.error ?? 'Export failed');
      }
      const blob = await res.blob();
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = 'along-sticker-batch-preview.pdf';
      a.click();
      URL.revokeObjectURL(url);
      setMessage('Sticker batch PDF downloaded (preview).');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Export failed');
    } finally {
      setExportingPdf(false);
    }
  }

  const attributed = qrPayments.filter((p) => p.trip_id);
  const unattributed = qrPayments.filter((p) => !p.trip_id);

  return (
    <div data-testid="finance-console">
      {error ? (
        <div className="error-banner" role="alert" data-testid="finance-error">
          {error}
        </div>
      ) : null}
      {message ? (
        <div className="card" role="status" data-testid="finance-success" style={{ marginBottom: 'var(--space-4)' }}>
          {message}
        </div>
      ) : null}

      <section style={{ marginBottom: 'var(--space-8)' }}>
        <h2 className="section-title">Dual-control queue</h2>
        {pendingAdjustments.length === 0 ? (
          <p className="empty-inline">No pending adjustments.</p>
        ) : (
          <table className="data-table" data-testid="dual-control-queue">
            <thead>
              <tr>
                <th>Driver</th>
                <th className="num">Amount</th>
                <th>Memo</th>
                <th>Requested by</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {pendingAdjustments.map((row) => {
                const isOwnRequest = currentAdminId != null && row.requested_by === currentAdminId;
                return (
                  <tr key={row.id} data-testid={`pending-adjustment-${row.id}`}>
                    <td>
                      <Link href={`/${citySlug}/drivers/${row.driver_id}`}>
                        {row.driver_code ?? row.driver_id.slice(0, 8)}
                      </Link>
                    </td>
                    <td className="num">{formatMoney(row.amount, row.currency)}</td>
                    <td>{row.memo}</td>
                    <td>{row.requested_by_name ?? row.requested_by.slice(0, 8)}</td>
                    <td>
                      <button
                        type="button"
                        className="btn btn-primary"
                        disabled={pending || isOwnRequest}
                        data-testid={`approve-adjustment-${row.id}`}
                        title={isOwnRequest ? 'Cannot approve your own request' : undefined}
                        onClick={() =>
                          runAction(() => approvePendingAdjustment(citySlug, row.id))
                        }
                      >
                        Approve
                      </button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </section>

      <section style={{ marginBottom: 'var(--space-8)' }}>
        <h2 className="section-title">Settlements</h2>
        {settlements.length === 0 ? (
          <p className="empty-inline">No settlements yet.</p>
        ) : (
          <table className="data-table" data-testid="settlements-table">
            <thead>
              <tr>
                <th>Driver</th>
                <th className="num">Amount</th>
                <th>Channel</th>
                <th>Status</th>
                <th>Created</th>
              </tr>
            </thead>
            <tbody>
              {settlements.map((row) => (
                <tr key={row.id}>
                  <td>{row.driver_code ?? row.driver_id.slice(0, 8)}</td>
                  <td className="num">{formatMoney(row.amount, row.currency)}</td>
                  <td>{row.channel}</td>
                  <td>
                    <span className={`badge badge-${row.status}`}>{humanize(row.status)}</span>
                  </td>
                  <td>{new Date(row.created_at).toLocaleString()}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>

      <section style={{ marginBottom: 'var(--space-8)' }}>
        <h2 className="section-title">Settlement agents</h2>
        <table className="data-table" data-testid="agents-table" style={{ marginBottom: 'var(--space-4)' }}>
          <thead>
            <tr>
              <th>Business</th>
              <th>Phone</th>
              <th>Active</th>
            </tr>
          </thead>
          <tbody>
            {agents.map((agent) => (
              <tr key={agent.id}>
                <td>{agent.business_name}</td>
                <td>{agent.phone ?? '—'}</td>
                <td>{agent.active ? 'Yes' : 'No'}</td>
              </tr>
            ))}
          </tbody>
        </table>

        <div className="card" data-testid="agent-form">
          <h3 className="sub-title">Add agent</h3>
          <div className="field">
            <label htmlFor="agent-name">Business name</label>
            <input
              id="agent-name"
              value={businessName}
              onChange={(e) => setBusinessName(e.target.value)}
              data-testid="agent-business-name"
            />
          </div>
          <div className="field">
            <label htmlFor="agent-phone">Phone (E.164)</label>
            <input
              id="agent-phone"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              data-testid="agent-phone"
            />
          </div>
          <button
            type="button"
            className="btn btn-primary"
            disabled={pending || !businessName.trim() || !phone.trim()}
            data-testid="create-agent"
            onClick={() =>
              runAction(() =>
                upsertSettlementAgent(citySlug, cityId, {
                  businessName,
                  phone,
                  active: true,
                })
              )
            }
          >
            Create agent
          </button>
        </div>
      </section>

      <section>
        <h2 className="section-title">Payouts</h2>
        {payouts.length === 0 ? (
          <p className="empty-inline">No payouts yet.</p>
        ) : (
          <table className="data-table" data-testid="payouts-table">
            <thead>
              <tr>
                <th>Driver</th>
                <th className="num">Amount</th>
                <th>Status</th>
                <th>Reference</th>
                <th>Created</th>
              </tr>
            </thead>
            <tbody>
              {payouts.map((row) => (
                <tr key={row.id}>
                  <td>{row.driver_code ?? row.driver_id.slice(0, 8)}</td>
                  <td className="num">{formatMoney(row.amount, row.currency)}</td>
                  <td>{row.status}</td>
                  <td>
                    <code>{row.provider_reference}</code>
                  </td>
                  <td>{new Date(row.created_at).toLocaleString()}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
        <p style={{ fontSize: '0.8125rem', color: 'var(--color-text-muted)', marginTop: 'var(--space-3)' }}>
          Paystack daily import reconciliation remains on the settlements pipeline.
        </p>
      </section>

      <section style={{ marginBottom: 'var(--space-8)' }} data-testid="qr-payments-section">
        <h2 className="section-title">QR payments</h2>
        {feeBearerReport ? (
          <div className="card" style={{ marginBottom: 'var(--space-4)' }} data-testid="fee-bearer-report">
            <h3 className="sub-title">Fee-bearer economics</h3>
            <dl
              style={{
                margin: 0,
                display: 'grid',
                gridTemplateColumns: 'max-content 1fr',
                gap: 'var(--space-2) var(--space-4)',
                fontSize: '0.875rem',
              }}
            >
              <dt>Config</dt>
              <dd>{feeBearerReport.fee_bearer}</dd>
              <dt>Succeeded QR payments</dt>
              <dd>{feeBearerReport.payment_count}</dd>
              <dt>Commission collected</dt>
              <dd>
                {formatMoney(feeBearerReport.commission_total, 'NGN')}
              </dd>
              <dt>Provider fees recorded</dt>
              <dd>
                {formatMoney(feeBearerReport.provider_fee_total, 'NGN')}
              </dd>
            </dl>
          </div>
        ) : null}

        <h3 className="sub-title">Attributed</h3>
        {attributed.length === 0 ? (
          <p className="empty-inline">No attributed QR payments.</p>
        ) : (
          <table className="data-table" data-testid="qr-payments-attributed" style={{ marginBottom: 'var(--space-4)' }}>
            <thead>
              <tr>
                <th>Driver</th>
                <th className="num">Amount</th>
                <th>Source</th>
                <th>Status</th>
                <th>Created</th>
              </tr>
            </thead>
            <tbody>
              {attributed.map((row) => (
                <tr key={row.id}>
                  <td>{row.driver_code ?? row.driver_id.slice(0, 8)}</td>
                  <td className="num">{formatMoney(row.amount, row.currency)}</td>
                  <td>{row.source}</td>
                  <td>{row.status}</td>
                  <td>{new Date(row.created_at).toLocaleString()}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}

        <h3 className="sub-title">Unattributed</h3>
        {unattributed.length === 0 ? (
          <p className="empty-inline">No unattributed QR payments.</p>
        ) : (
          <table className="data-table" data-testid="qr-payments-unattributed">
            <thead>
              <tr>
                <th>Driver</th>
                <th className="num">Amount</th>
                <th>Source</th>
                <th>Status</th>
                <th>Created</th>
              </tr>
            </thead>
            <tbody>
              {unattributed.map((row) => (
                <tr key={row.id}>
                  <td>{row.driver_code ?? row.driver_id.slice(0, 8)}</td>
                  <td className="num">{formatMoney(row.amount, row.currency)}</td>
                  <td>{row.source}</td>
                  <td>{row.status}</td>
                  <td>{new Date(row.created_at).toLocaleString()}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>

      <section data-testid="sticker-batch-section">
        <h2 className="section-title">Sticker batches (preview)</h2>
        <p style={{ fontSize: '0.875rem', color: 'var(--color-text-muted)' }}>
          Export QR + plate + code labels marked STAGING. Not for production vehicles.
        </p>
        {stickerDrivers.length === 0 ? (
          <p className="empty-inline">No drivers with codes in this city.</p>
        ) : (
          <>
            <table className="data-table" data-testid="sticker-batch-drivers" style={{ marginBottom: 'var(--space-4)' }}>
              <thead>
                <tr>
                  <th />
                  <th>Code</th>
                  <th>Plate</th>
                </tr>
              </thead>
              <tbody>
                {stickerDrivers.map((driver) => (
                  <tr key={driver.id}>
                    <td>
                      <input
                        type="checkbox"
                        checked={selectedStickerDrivers.has(driver.id)}
                        onChange={() => toggleStickerDriver(driver.id)}
                        data-testid={`sticker-select-${driver.driver_code}`}
                      />
                    </td>
                    <td>{driver.driver_code}</td>
                    <td>{driver.plate ?? '—'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
            <button
              type="button"
              className="btn btn-primary"
              disabled={pending || exportingPdf || selectedStickerDrivers.size === 0}
              data-testid="export-sticker-batch"
              onClick={() => void exportStickerBatch()}
            >
              Export PDF preview
            </button>
          </>
        )}
      </section>
    </div>
  );
}
