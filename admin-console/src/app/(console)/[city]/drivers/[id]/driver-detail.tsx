'use client';

import Link from 'next/link';
import { useState, useTransition } from 'react';
import { formatMoney, maskPhone, standingLabel } from '@/lib/drivers/format';
import { evidenceBullets, flagTypeLabel, scorePct } from '@/lib/integrity/format';
import type { IntegrityFlagRow } from '@/lib/integrity/types';
import { STANDING_OPTIONS } from '@/lib/integrity/types';
import {
  notifyGuarantor,
  postManualAdjustment,
  transitionDriverStanding,
} from './actions';

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
  balance: number;
  currency: string;
  ledger: LedgerEntryRow[];
  transitions: StandingTransitionRow[];
  flags: IntegrityFlagRow[];
  guarantor: GuarantorRow | null;
}

type Tab = 'overview' | 'ledger' | 'standing' | 'flags' | 'guarantor' | 'payments';

interface DriverDetailProps {
  citySlug: string;
  driver: DriverDetailData;
}

export function DriverDetail({ citySlug, driver }: DriverDetailProps) {
  const [tab, setTab] = useState<Tab>('overview');
  const [amount, setAmount] = useState('');
  const [memo, setMemo] = useState('');
  const [toStanding, setToStanding] = useState<string>(STANDING_OPTIONS[0].value);
  const [standingReason, setStandingReason] = useState('');
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [pending, startTransition] = useTransition();

  function runAction(action: () => Promise<{ ok: boolean; message?: string; error?: string }>) {
    setMessage(null);
    setError(null);
    startTransition(async () => {
      const result = await action();
      if (result.ok) setMessage(result.message ?? 'Done.');
      else setError(result.error ?? 'Action failed.');
    });
  }

  const tabs: { id: Tab; label: string }[] = [
    { id: 'overview', label: 'Overview' },
    { id: 'ledger', label: 'Ledger' },
    { id: 'standing', label: 'Standing' },
    { id: 'flags', label: 'Flags' },
    { id: 'guarantor', label: 'Guarantor' },
    { id: 'payments', label: 'Payments' },
  ];

  return (
    <div data-testid="driver-detail">
      <div className="card" style={{ marginBottom: 'var(--space-4)' }}>
        <h2 style={{ margin: '0 0 var(--space-2)' }}>
          {driver.display_name ?? driver.driver_code ?? 'Driver'}
        </h2>
        <p style={{ margin: 0, fontSize: '0.875rem', color: 'var(--color-text-muted)' }}>
          {maskPhone(driver.phone_e164)} · {driver.city_name} ·{' '}
          <span className={`badge badge-${driver.verified_status}`}>{driver.verified_status}</span>{' '}
          · {standingLabel(driver.standing)} · balance {formatMoney(driver.balance, driver.currency)}
        </p>
      </div>

      {error ? (
        <div className="error-banner" role="alert" data-testid="driver-error">
          {error}
        </div>
      ) : null}
      {message ? (
        <div className="card" role="status" data-testid="driver-success" style={{ marginBottom: 'var(--space-4)' }}>
          {message}
        </div>
      ) : null}

      <nav className="nav-links" aria-label="Driver sections" style={{ marginBottom: 'var(--space-4)' }}>
        {tabs.map(({ id, label }) => (
          <button
            key={id}
            type="button"
            className="btn"
            data-testid={`driver-tab-${id}`}
            style={{
              background: tab === id ? 'var(--color-brand-yellow)' : undefined,
              color: tab === id ? 'var(--color-brand-yellow-on)' : undefined,
            }}
            onClick={() => setTab(id)}
          >
            {label}
          </button>
        ))}
      </nav>

      {tab === 'overview' ? (
        <div className="card" data-testid="driver-overview">
          <dl
            style={{
              margin: 0,
              display: 'grid',
              gridTemplateColumns: 'max-content 1fr',
              gap: 'var(--space-2) var(--space-4)',
              fontSize: '0.875rem',
            }}
          >
            <dt style={{ color: 'var(--color-text-muted)' }}>Driver code</dt>
            <dd style={{ margin: 0 }}>{driver.driver_code ?? '—'}</dd>
            <dt style={{ color: 'var(--color-text-muted)' }}>Rating</dt>
            <dd style={{ margin: 0 }}>
              {driver.rating != null ? `${driver.rating.toFixed(2)} (${driver.rating_count})` : '—'}
            </dd>
            <dt style={{ color: 'var(--color-text-muted)' }}>Open flags</dt>
            <dd style={{ margin: 0 }}>
              {driver.flags.filter((f) => f.status === 'open').length}
            </dd>
          </dl>
          <p style={{ marginTop: 'var(--space-4)' }}>
            <Link href={`/${citySlug}/integrity`}>View integrity queue</Link>
          </p>
        </div>
      ) : null}

      {tab === 'ledger' ? (
        <div data-testid="driver-ledger">
          <table className="data-table" style={{ marginBottom: 'var(--space-6)' }}>
            <thead>
              <tr>
                <th>Date</th>
                <th>Type</th>
                <th>Amount</th>
                <th>Balance</th>
                <th>Memo</th>
              </tr>
            </thead>
            <tbody>
              {driver.ledger.map((entry) => (
                <tr key={entry.id}>
                  <td>{new Date(entry.created_at).toLocaleString()}</td>
                  <td>{entry.entry_type}</td>
                  <td>{formatMoney(entry.amount, entry.currency)}</td>
                  <td>{formatMoney(entry.balance_after, entry.currency)}</td>
                  <td>{entry.memo ?? '—'}</td>
                </tr>
              ))}
            </tbody>
          </table>

          <div className="card">
            <h3 style={{ marginTop: 0 }}>Manual adjustment</h3>
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
                  postManualAdjustment(citySlug, driver.id, Number(amount), memo)
                )
              }
            >
              Submit adjustment
            </button>
          </div>
        </div>
      ) : null}

      {tab === 'standing' ? (
        <div data-testid="driver-standing">
          <table className="data-table" style={{ marginBottom: 'var(--space-6)' }}>
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
                  <td>{row.from_standing ? standingLabel(row.from_standing) : '—'}</td>
                  <td>{standingLabel(row.to_standing)}</td>
                  <td>{row.reason}</td>
                </tr>
              ))}
            </tbody>
          </table>

          <div className="card">
            <h3 style={{ marginTop: 0 }}>Transition standing</h3>
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
                  transitionDriverStanding(citySlug, driver.id, toStanding, standingReason)
                )
              }
            >
              Apply transition
            </button>
          </div>
        </div>
      ) : null}

      {tab === 'flags' ? (
        <div data-testid="driver-flags">
          {driver.flags.length === 0 ? (
            <p style={{ color: 'var(--color-text-muted)' }}>No reconciliation flags.</p>
          ) : (
            driver.flags.map((flag) => (
              <div key={flag.id} className="card" style={{ marginBottom: 'var(--space-3)' }}>
                <strong>{flagTypeLabel(flag.flag_type)}</strong> · {scorePct(flag.score)} ·{' '}
                <span className={`badge badge-${flag.status}`}>{flag.status}</span>
                <ul style={{ fontSize: '0.875rem', marginBottom: 0 }}>
                  {evidenceBullets(flag.evidence).map((item) => (
                    <li key={item}>{item}</li>
                  ))}
                </ul>
              </div>
            ))
          )}
        </div>
      ) : null}

      {tab === 'guarantor' ? (
        <div className="card" data-testid="driver-guarantor">
          {driver.guarantor ? (
            <>
              <p>
                <strong>{driver.guarantor.guarantor_name}</strong> ·{' '}
                {maskPhone(driver.guarantor.guarantor_phone_e164)}
              </p>
              <p style={{ fontSize: '0.875rem', color: 'var(--color-text-muted)' }}>
                Acknowledged:{' '}
                {driver.guarantor.acknowledged_at
                  ? new Date(driver.guarantor.acknowledged_at).toLocaleString()
                  : 'Pending'}
                · Last notified:{' '}
                {driver.guarantor.last_notified_at
                  ? new Date(driver.guarantor.last_notified_at).toLocaleString()
                  : 'Never'}
              </p>
              <button
                type="button"
                className="btn btn-primary"
                disabled={pending}
                data-testid="notify-guarantor"
                onClick={() => runAction(() => notifyGuarantor(citySlug, driver.id))}
              >
                Notify guarantor
              </button>
            </>
          ) : (
            <p style={{ color: 'var(--color-text-muted)' }}>No guarantor on file.</p>
          )}
        </div>
      ) : null}

      {tab === 'payments' ? (
        <div className="card" data-testid="driver-payments-stub">
          <p style={{ color: 'var(--color-text-muted)' }}>
            QR payments, driver code rotation, and sticker requests — coming with P4-D-02.
          </p>
        </div>
      ) : null}
    </div>
  );
}
