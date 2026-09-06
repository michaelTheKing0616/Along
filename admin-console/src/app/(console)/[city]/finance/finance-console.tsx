'use client';

import Link from 'next/link';
import { useState, useTransition } from 'react';
import { formatMoney } from '@/lib/drivers/format';
import type {
  PendingAdjustmentRow,
  PayoutRow,
  SettlementAgentRow,
  SettlementRow,
} from '@/lib/finance/types';
import { approvePendingAdjustment, upsertSettlementAgent } from './actions';

interface FinanceConsoleProps {
  citySlug: string;
  cityId: string;
  settlements: SettlementRow[];
  agents: SettlementAgentRow[];
  pendingAdjustments: PendingAdjustmentRow[];
  payouts: PayoutRow[];
  currentAdminId: string | null;
}

export function FinanceConsole({
  citySlug,
  cityId,
  settlements,
  agents,
  pendingAdjustments,
  payouts,
  currentAdminId,
}: FinanceConsoleProps) {
  const [businessName, setBusinessName] = useState('');
  const [phone, setPhone] = useState('');
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
        <h2 style={{ fontSize: '1.125rem' }}>Dual-control queue</h2>
        {pendingAdjustments.length === 0 ? (
          <p style={{ color: 'var(--color-text-muted)' }}>No pending adjustments.</p>
        ) : (
          <table className="data-table" data-testid="dual-control-queue">
            <thead>
              <tr>
                <th>Driver</th>
                <th>Amount</th>
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
                    <td>{formatMoney(row.amount, row.currency)}</td>
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
        <h2 style={{ fontSize: '1.125rem' }}>Settlements</h2>
        {settlements.length === 0 ? (
          <p style={{ color: 'var(--color-text-muted)' }}>No settlements yet.</p>
        ) : (
          <table className="data-table" data-testid="settlements-table">
            <thead>
              <tr>
                <th>Driver</th>
                <th>Amount</th>
                <th>Channel</th>
                <th>Status</th>
                <th>Created</th>
              </tr>
            </thead>
            <tbody>
              {settlements.map((row) => (
                <tr key={row.id}>
                  <td>{row.driver_code ?? row.driver_id.slice(0, 8)}</td>
                  <td>{formatMoney(row.amount, row.currency)}</td>
                  <td>{row.channel}</td>
                  <td>
                    <span className={`badge badge-${row.status}`}>{row.status}</span>
                  </td>
                  <td>{new Date(row.created_at).toLocaleString()}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>

      <section style={{ marginBottom: 'var(--space-8)' }}>
        <h2 style={{ fontSize: '1.125rem' }}>Settlement agents</h2>
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
          <h3 style={{ marginTop: 0 }}>Add agent</h3>
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
        <h2 style={{ fontSize: '1.125rem' }}>Payouts</h2>
        {payouts.length === 0 ? (
          <p style={{ color: 'var(--color-text-muted)' }}>No payouts yet.</p>
        ) : (
          <table className="data-table" data-testid="payouts-table">
            <thead>
              <tr>
                <th>Driver</th>
                <th>Amount</th>
                <th>Status</th>
                <th>Reference</th>
                <th>Created</th>
              </tr>
            </thead>
            <tbody>
              {payouts.map((row) => (
                <tr key={row.id}>
                  <td>{row.driver_code ?? row.driver_id.slice(0, 8)}</td>
                  <td>{formatMoney(row.amount, row.currency)}</td>
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
          QR payments and Paystack daily import reconciliation — deferred to P4-D-02.
        </p>
      </section>
    </div>
  );
}
