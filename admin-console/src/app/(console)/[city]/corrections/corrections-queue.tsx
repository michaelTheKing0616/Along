'use client';

import { useMemo, useState, useTransition } from 'react';
import {
  formatDeltaPct,
  formatMoney,
  queueAgeLabel,
} from '@/lib/corrections/format';
import type { FareCorrectionQueueRow } from '@/lib/corrections/types';
import { approveFareCorrection, rejectFareCorrection } from './actions';

interface CorrectionsQueueProps {
  citySlug: string;
  initialRows: FareCorrectionQueueRow[];
  initialSelectedId: string | null;
}

export function CorrectionsQueue({
  citySlug,
  initialRows,
  initialSelectedId,
}: CorrectionsQueueProps) {
  const [rows, setRows] = useState(initialRows);
  const [selectedId, setSelectedId] = useState<string | null>(initialSelectedId);
  const [note, setNote] = useState('');
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [pending, startTransition] = useTransition();

  const selected = useMemo(
    () => rows.find((r) => r.id === selectedId) ?? null,
    [rows, selectedId]
  );

  function refreshLocal(id: string, status: FareCorrectionQueueRow['status']) {
    setRows((prev) => prev.map((r) => (r.id === id ? { ...r, status } : r)));
  }

  function runAction(action: () => Promise<{ ok: boolean; message?: string; error?: string }>) {
    setMessage(null);
    setError(null);
    startTransition(async () => {
      const result = await action();
      if (result.ok) {
        setMessage(result.message ?? 'Done.');
      } else {
        setError(result.error ?? 'Action failed.');
      }
    });
  }

  return (
    <div data-testid="corrections-queue">
      {error ? (
        <div className="error-banner" role="alert" data-testid="corrections-error">
          {error}
        </div>
      ) : null}
      {message ? (
        <div
          className="card"
          role="status"
          data-testid="corrections-success"
          style={{
            marginBottom: 'var(--space-4)',
            borderColor: 'var(--color-primary)',
            fontSize: '0.875rem',
          }}
        >
          {message}
        </div>
      ) : null}

      {rows.length === 0 ? (
        <p style={{ color: 'var(--color-text-muted)' }}>No fare corrections for this city.</p>
      ) : (
        <>
          <table className="data-table" data-testid="corrections-table">
            <thead>
              <tr>
                <th>Route / leg</th>
                <th>Proposed</th>
                <th>Current</th>
                <th>Δ</th>
                <th>Submitter</th>
                <th>Status</th>
                <th>Age</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr
                  key={row.id}
                  data-testid={`correction-row-${row.id}`}
                  onClick={() => setSelectedId(row.id)}
                  style={{
                    cursor: 'pointer',
                    background: row.id === selectedId ? 'var(--color-bg)' : undefined,
                  }}
                >
                  <td>
                    {row.route_label ?? '—'}
                    {row.is_mad_outlier ? (
                      <span
                        className="badge badge-discrepant"
                        data-testid={`mad-badge-${row.id}`}
                        style={{ marginLeft: 'var(--space-2)' }}
                      >
                        MAD
                      </span>
                    ) : null}
                    {row.is_negotiation ? (
                      <span
                        className="badge badge-candidate"
                        data-testid={`negotiation-badge-${row.id}`}
                        style={{ marginLeft: 'var(--space-2)' }}
                      >
                        Negotiation
                      </span>
                    ) : null}
                  </td>
                  <td>{formatMoney(row.proposed_fare, row.currency)}</td>
                  <td>{formatMoney(row.current_fare, row.currency)}</td>
                  <td>{formatDeltaPct(row.delta_pct)}</td>
                  <td>{row.submitter_label}</td>
                  <td>
                    <span className={`badge badge-${row.status}`}>{row.status}</span>
                  </td>
                  <td>{queueAgeLabel(row.created_at)}</td>
                </tr>
              ))}
            </tbody>
          </table>

          {selected ? (
            <section style={{ marginTop: 'var(--space-6)' }} data-testid="correction-detail">
              <h2 style={{ margin: '0 0 var(--space-2)', fontSize: '1.125rem' }}>
                Fare correction detail
              </h2>

              <div className="card" style={{ marginBottom: 'var(--space-4)' }}>
                <dl
                  style={{
                    margin: 0,
                    display: 'grid',
                    gridTemplateColumns: 'max-content 1fr',
                    gap: 'var(--space-2) var(--space-4)',
                    fontSize: '0.875rem',
                  }}
                >
                  <dt style={{ color: 'var(--color-text-muted)' }}>Proposed</dt>
                  <dd style={{ margin: 0 }}>{formatMoney(selected.proposed_fare, selected.currency)}</dd>
                  <dt style={{ color: 'var(--color-text-muted)' }}>Current / shown</dt>
                  <dd style={{ margin: 0 }}>
                    {formatMoney(selected.current_fare, selected.currency)}
                    {selected.fare_shown != null &&
                    selected.current_fare != null &&
                    selected.fare_shown !== selected.current_fare ? (
                      <span style={{ color: 'var(--color-text-muted)' }}>
                        {' '}
                        (shown {formatMoney(selected.fare_shown, selected.currency)})
                      </span>
                    ) : null}
                  </dd>
                  <dt style={{ color: 'var(--color-text-muted)' }}>Delta</dt>
                  <dd style={{ margin: 0 }}>{formatDeltaPct(selected.delta_pct)}</dd>
                  <dt style={{ color: 'var(--color-text-muted)' }}>Submitter trust</dt>
                  <dd style={{ margin: 0 }} data-testid="submitter-trust">
                    {selected.submitter_trust != null
                      ? selected.submitter_trust.toFixed(3)
                      : '—'}{' '}
                    ({selected.submitter_label})
                  </dd>
                  {selected.stage_from && selected.stage_to ? (
                    <>
                      <dt style={{ color: 'var(--color-text-muted)' }}>Stages</dt>
                      <dd style={{ margin: 0 }}>
                        {selected.stage_from} → {selected.stage_to}
                      </dd>
                    </>
                  ) : null}
                  {selected.trip_id ? (
                    <>
                      <dt style={{ color: 'var(--color-text-muted)' }}>Trip</dt>
                      <dd style={{ margin: 0 }}>
                        <code data-testid="correction-trip-link">{selected.trip_id}</code>
                      </dd>
                    </>
                  ) : null}
                </dl>

                {selected.is_mad_outlier ? (
                  <p
                    data-testid="mad-outlier-banner"
                    style={{
                      margin: 'var(--space-3) 0 0',
                      fontSize: '0.8125rem',
                      color: 'var(--color-warning, #b45309)',
                    }}
                  >
                    Proposed fare exceeds neighbour median by more than the configured MAD threshold.
                  </p>
                ) : null}
              </div>

              {selected.status === 'pending' ? (
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: 'var(--space-2)' }}>
                  <button
                    type="button"
                    className="btn btn-primary"
                    disabled={pending}
                    data-testid="approve-correction"
                    onClick={() =>
                      runAction(async () => {
                        const result = await approveFareCorrection(
                          citySlug,
                          selected.id,
                          note || undefined
                        );
                        if (result.ok) refreshLocal(selected.id, 'approved');
                        return result;
                      })
                    }
                  >
                    Approve
                  </button>
                  <div style={{ display: 'flex', gap: 'var(--space-2)', alignItems: 'flex-end' }}>
                    <div className="field" style={{ marginBottom: 0 }}>
                      <label htmlFor="correction-note">Note (optional)</label>
                      <input
                        id="correction-note"
                        value={note}
                        onChange={(e) => setNote(e.target.value)}
                        placeholder="Review note"
                        data-testid="correction-note"
                      />
                    </div>
                    <button
                      type="button"
                      className="btn"
                      disabled={pending}
                      data-testid="reject-correction"
                      onClick={() =>
                        runAction(async () => {
                          const result = await rejectFareCorrection(
                            citySlug,
                            selected.id,
                            note || undefined
                          );
                          if (result.ok) refreshLocal(selected.id, 'rejected');
                          return result;
                        })
                      }
                    >
                      Reject
                    </button>
                  </div>
                </div>
              ) : null}
            </section>
          ) : null}
        </>
      )}
    </div>
  );
}
