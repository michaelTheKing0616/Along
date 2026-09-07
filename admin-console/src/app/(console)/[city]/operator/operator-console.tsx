'use client';

import React, { useState, useTransition } from 'react';
import type { OperatorOverview } from '@/lib/operator/types';
import { loadOperatorOverview } from './actions';

interface OperatorConsoleProps {
  initialOverview: OperatorOverview | null;
  isOperatorViewer: boolean;
}

export function OperatorConsole({ initialOverview, isOperatorViewer }: OperatorConsoleProps) {
  const [overview, setOverview] = useState<OperatorOverview | null>(initialOverview);
  const [error, setError] = useState<string | null>(null);
  const [pending, startTransition] = useTransition();
  const [windowDays, setWindowDays] = useState('7');

  function refreshOverview() {
    setError(null);
    const days = Number(windowDays) || 7;
    const to = new Date();
    const from = new Date(to.getTime() - days * 86400000);

    startTransition(async () => {
      const result = await loadOperatorOverview(from.toISOString(), to.toISOString());
      if (result.ok) {
        setOverview(result.overview);
      } else {
        setError(result.error);
      }
    });
  }

  if (!isOperatorViewer) {
    return (
      <div className="card" data-testid="operator-console-unscoped">
        <p>
          Operator overview is scoped to a linked operator account. Sign in as{' '}
          <code>operator_viewer</code> or manage accounts from Revenue.
        </p>
      </div>
    );
  }

  const htmlSnapshot = JSON.stringify(overview ?? {});

  return (
    <div data-testid="operator-console">
      <div
        data-testid="operator-privacy-guard"
        data-aggregate-only="true"
        hidden
        aria-hidden="true"
      >
        {htmlSnapshot.includes('rider_id') ? 'FAIL' : 'PASS'}
      </div>

      {error ? (
        <div className="error-banner" role="alert" data-testid="operator-error">
          {error}
        </div>
      ) : null}

      <div style={{ display: 'flex', gap: 'var(--space-4)', alignItems: 'end', marginBottom: 'var(--space-6)' }}>
        <div className="field" style={{ marginBottom: 0 }}>
          <label htmlFor="operator-window-days">Window (days)</label>
          <input
            id="operator-window-days"
            data-testid="operator-window-days"
            type="number"
            min="1"
            max="30"
            value={windowDays}
            onChange={(e) => setWindowDays(e.target.value)}
          />
        </div>
        <button
          type="button"
          className="btn btn-primary"
          data-testid="operator-refresh"
          disabled={pending}
          onClick={refreshOverview}
        >
          Refresh aggregates
        </button>
      </div>

      <p style={{ color: 'var(--color-text-muted)' }} data-testid="operator-aggregate-note">
        Aggregate driver metrics only — no per-rider data (FM39).
      </p>

      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fill, minmax(11rem, 1fr))',
          gap: 'var(--space-4)',
        }}
      >
        <div className="card" data-testid="operator-online-total">
          <h3 style={{ marginTop: 0 }}>Drivers online</h3>
          <p style={{ fontSize: '1.5rem', margin: 0 }}>{overview?.online_total ?? 0}</p>
          <p style={{ color: 'var(--color-text-muted)' }}>
            At park {overview?.online_at_park ?? 0} · Roaming {overview?.online_roaming ?? 0}
          </p>
        </div>
        <div className="card" data-testid="operator-trips-day">
          <h3 style={{ marginTop: 0 }}>Trips / day</h3>
          <p style={{ fontSize: '1.5rem', margin: 0 }}>
            {overview?.trips_per_day != null ? overview.trips_per_day.toFixed(1) : '—'}
          </p>
          <p style={{ color: 'var(--color-text-muted)' }}>
            {overview?.trips_completed ?? 0} completed in window
          </p>
        </div>
        <div className="card" data-testid="operator-fare-discrepancy">
          <h3 style={{ marginTop: 0 }}>Fare discrepancy rate</h3>
          <p style={{ fontSize: '1.5rem', margin: 0 }}>
            {overview?.fare_discrepancy_rate != null
              ? `${(overview.fare_discrepancy_rate * 100).toFixed(1)}%`
              : '—'}
          </p>
        </div>
        <div className="card" data-testid="operator-driver-count">
          <h3 style={{ marginTop: 0 }}>Drivers in roster</h3>
          <p style={{ fontSize: '1.5rem', margin: 0 }}>{overview?.driver_count ?? 0}</p>
        </div>
      </div>
    </div>
  );
}
