'use client';

import { useEffect, useMemo, useState, useTransition } from 'react';
import { redactOcrExtract } from '@/lib/verification/redact-ocr';
import { queueAgeLabel } from '@/lib/verification/format';
import type { VerificationQueueRow } from '@/lib/verification/types';
import { approveVerification, rejectVerification } from './actions';

interface VerificationQueueProps {
  citySlug: string;
  initialRows: VerificationQueueRow[];
  initialSelectedId: string | null;
}

type DocumentViewState = {
  url: string;
  watermark: { reviewerId: string; viewedAt: string };
};

function DocumentPanel({
  row,
  label,
  onViewed,
}: {
  row: VerificationQueueRow;
  label: string;
  onViewed: (verificationId: string) => void;
}) {
  const [doc, setDoc] = useState<DocumentViewState | null>(null);
  const [docError, setDocError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function loadDocument() {
    setLoading(true);
    setDocError(null);
    try {
      const res = await fetch(`/api/verification/${row.id}/document`);
      const body = (await res.json()) as DocumentViewState & { error?: string; logged?: boolean };
      if (!res.ok) {
        if (body.logged) onViewed(row.id);
        throw new Error(body.error ?? 'Failed to load document');
      }
      setDoc(body);
      onViewed(row.id);
    } catch (err) {
      setDocError(err instanceof Error ? err.message : 'Failed to load document');
    } finally {
      setLoading(false);
    }
  }

  const redacted = useMemo(() => redactOcrExtract(row.ocr_extract), [row.ocr_extract]);

  return (
    <div className="card verification-doc-panel" data-testid={`verification-doc-${row.document_type}`}>
      <h3 style={{ margin: '0 0 var(--space-2)', fontSize: '0.9375rem' }}>{label}</h3>
      <p style={{ margin: '0 0 var(--space-2)', fontSize: '0.8125rem', color: 'var(--color-text-muted)' }}>
        {row.document_type} · submitted {new Date(row.submitted_at).toLocaleString()}
      </p>

      {!doc ? (
        <button
          type="button"
          className="btn"
          disabled={loading || !row.storage_path}
          data-testid={`view-document-${row.id}`}
          onClick={() => void loadDocument()}
        >
          {loading ? 'Loading…' : 'View document'}
        </button>
      ) : (
        <div className="verification-doc-viewer" data-testid="verification-doc-viewer">
          <div className="verification-doc-frame">
            <div
              className="verification-doc-image"
              role="img"
              aria-label={`${row.document_type} document`}
              style={{ backgroundImage: `url(${doc.url})` }}
            />
            <div className="verification-doc-watermark" aria-hidden="true">
              {doc.watermark.reviewerId.slice(0, 8)}… ·{' '}
              {new Date(doc.watermark.viewedAt).toLocaleString()}
            </div>
          </div>
        </div>
      )}

      {docError ? (
        <p className="verification-doc-error" role="alert" data-testid="verification-doc-error">
          {docError}
        </p>
      ) : null}

      <div style={{ marginTop: 'var(--space-3)' }}>
        <h4 style={{ margin: '0 0 var(--space-1)', fontSize: '0.8125rem' }}>OCR extract (redacted)</h4>
        <pre className="verification-ocr-pre">{JSON.stringify(redacted, null, 2)}</pre>
      </div>

      {row.face_match_score != null ? (
        <p style={{ marginTop: 'var(--space-2)', fontSize: '0.875rem' }}>
          Face-match score: <strong>{row.face_match_score.toFixed(3)}</strong>
        </p>
      ) : null}
    </div>
  );
}

export function VerificationQueue({
  citySlug,
  initialRows,
  initialSelectedId,
}: VerificationQueueProps) {
  const [rows, setRows] = useState(initialRows);
  const [selectedId, setSelectedId] = useState<string | null>(initialSelectedId);
  const [rejectReason, setRejectReason] = useState('');
  const [womenOnlyEligible, setWomenOnlyEligible] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [viewedIds, setViewedIds] = useState<Set<string>>(new Set());
  const [pending, startTransition] = useTransition();

  const selected = useMemo(
    () => rows.find((r) => r.id === selectedId) ?? null,
    [rows, selectedId]
  );

  const driverPendingDocs = useMemo(() => {
    if (!selected) return [];
    return rows.filter((r) => r.driver_id === selected.driver_id && r.status === 'pending');
  }, [rows, selected]);

  useEffect(() => {
    setWomenOnlyEligible(false);
    setRejectReason('');
  }, [selectedId]);

  function markViewed(id: string) {
    setViewedIds((prev) => new Set(prev).add(id));
  }

  function refreshLocal(id: string, status: VerificationQueueRow['status']) {
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

  const duplicateBlocksVerifier =
    selected?.duplicate && selected.status === 'pending';

  return (
    <div data-testid="verification-queue">
      {error ? (
        <div className="error-banner" role="alert" data-testid="verification-error">
          {error}
        </div>
      ) : null}
      {message ? (
        <div
          className="card"
          role="status"
          data-testid="verification-success"
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
        <p style={{ color: 'var(--color-text-muted)' }}>No verification submissions for this city.</p>
      ) : (
        <>
          <table className="data-table" data-testid="verification-table">
            <thead>
              <tr>
                <th>Driver</th>
                <th>Document</th>
                <th>Status</th>
                <th>Age</th>
                <th>Vehicle</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr
                  key={row.id}
                  data-testid={`verification-row-${row.id}`}
                  onClick={() => setSelectedId(row.id)}
                  style={{
                    cursor: 'pointer',
                    background: row.id === selectedId ? 'var(--color-bg)' : undefined,
                  }}
                >
                  <td>{row.driver_display_name ?? row.driver_id.slice(0, 8)}</td>
                  <td>{row.document_type}</td>
                  <td>
                    <span className={`badge badge-${row.status}`}>{row.status}</span>
                  </td>
                  <td>{queueAgeLabel(row.submitted_at)}</td>
                  <td>{row.vehicle_plate ?? '—'}</td>
                </tr>
              ))}
            </tbody>
          </table>

          {selected ? (
            <section style={{ marginTop: 'var(--space-6)' }} data-testid="verification-detail">
              <h2 style={{ margin: '0 0 var(--space-2)', fontSize: '1.125rem' }}>
                {selected.driver_display_name ?? 'Driver'}{' '}
                <span style={{ fontWeight: 400, color: 'var(--color-text-muted)' }}>
                  ({selected.driver_phone_masked})
                </span>
              </h2>

              {selected.duplicate ? (
                <div
                  className="error-banner"
                  role="alert"
                  data-testid="duplicate-hash-banner"
                  style={{ marginBottom: 'var(--space-4)' }}
                >
                  Duplicate identity hash — matches driver{' '}
                  <strong>{selected.other_driver_masked ?? 'unknown'}</strong>. Approval requires{' '}
                  <strong>ops_lead</strong>.
                </div>
              ) : null}

              {selected.vehicle_plate ? (
                <div className="card" style={{ marginBottom: 'var(--space-4)' }}>
                  <h3 style={{ margin: '0 0 var(--space-2)', fontSize: '0.9375rem' }}>Vehicle</h3>
                  <p style={{ margin: 0, fontSize: '0.875rem' }}>
                    {selected.vehicle_plate}
                    {selected.vehicle_make_model ? ` · ${selected.vehicle_make_model}` : ''}
                    {selected.vehicle_color ? ` · ${selected.vehicle_color}` : ''}
                    {selected.vehicle_seat_capacity != null
                      ? ` · ${selected.vehicle_seat_capacity} seats`
                      : ''}
                  </p>
                </div>
              ) : null}

              <div
                className="verification-compare-row"
                data-testid="verification-compare-row"
                style={{ display: 'flex', gap: 'var(--space-4)', flexWrap: 'wrap' }}
              >
                {driverPendingDocs.map((doc, index) => (
                  <DocumentPanel
                    key={doc.id}
                    row={doc}
                    label={driverPendingDocs.length > 1 ? `Document ${index + 1}` : 'Document'}
                    onViewed={markViewed}
                  />
                ))}
              </div>

              {selected.status === 'pending' ? (
                <div style={{ marginTop: 'var(--space-4)' }}>
                  {selected.driver_gender === 'female' ? (
                    <label
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: 'var(--space-2)',
                        marginBottom: 'var(--space-3)',
                        fontSize: '0.875rem',
                      }}
                    >
                      <input
                        type="checkbox"
                        checked={womenOnlyEligible}
                        onChange={(e) => setWomenOnlyEligible(e.target.checked)}
                        data-testid="women-only-eligible"
                      />
                      Mark women-only eligible
                    </label>
                  ) : null}

                  <div style={{ display: 'flex', flexWrap: 'wrap', gap: 'var(--space-2)' }}>
                    <button
                      type="button"
                      className="btn btn-primary"
                      disabled={pending || duplicateBlocksVerifier}
                      data-testid="approve-verification"
                      onClick={() =>
                        runAction(async () => {
                          const result = await approveVerification(
                            citySlug,
                            selected.id,
                            womenOnlyEligible || undefined
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
                        <label htmlFor="reject-reason">Reject reason</label>
                        <input
                          id="reject-reason"
                          value={rejectReason}
                          onChange={(e) => setRejectReason(e.target.value)}
                          placeholder="Required"
                          data-testid="reject-reason"
                        />
                      </div>
                      <button
                        type="button"
                        className="btn"
                        disabled={pending || !rejectReason.trim()}
                        data-testid="reject-verification"
                        onClick={() =>
                          runAction(async () => {
                            const result = await rejectVerification(
                              citySlug,
                              selected.id,
                              rejectReason
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
                </div>
              ) : null}

              {viewedIds.has(selected.id) ? (
                <p
                  data-testid="verification-viewed-flag"
                  style={{
                    marginTop: 'var(--space-3)',
                    fontSize: '0.8125rem',
                    color: 'var(--color-text-muted)',
                  }}
                >
                  Document view logged for audit.
                </p>
              ) : null}
            </section>
          ) : null}
        </>
      )}
    </div>
  );
}
