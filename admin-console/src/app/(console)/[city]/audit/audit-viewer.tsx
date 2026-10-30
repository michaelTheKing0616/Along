'use client';

import { useMemo, useState, useTransition } from 'react';
import { changedAuditKeys, formatAuditJson } from '@/lib/audit/diff';
import type { AuditLogPage, AuditLogRow } from '@/lib/audit/types';
import { loadAuditPage } from './actions';
import { shortId } from '@/lib/ui/label';

interface AuditViewerProps {
  citySlug: string;
  initialPage: AuditLogPage;
}

export function AuditViewer({ citySlug, initialPage }: AuditViewerProps) {
  const [page, setPage] = useState(initialPage);
  const [selected, setSelected] = useState<AuditLogRow | null>(initialPage.rows[0] ?? null);
  const [actionFilter, setActionFilter] = useState('');
  const [targetTypeFilter, setTargetTypeFilter] = useState('');
  const [actorRoleFilter, setActorRoleFilter] = useState('');
  const [targetIdFilter, setTargetIdFilter] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [pending, startTransition] = useTransition();

  const changedKeys = useMemo(
    () => changedAuditKeys(selected?.before ?? null, selected?.after ?? null),
    [selected]
  );

  function applyFilters(cursor?: number) {
    setError(null);
    startTransition(async () => {
      const result = await loadAuditPage({
        citySlug,
        cursor,
        action: actionFilter || undefined,
        targetType: targetTypeFilter || undefined,
        actorRole: actorRoleFilter || undefined,
        targetId: targetIdFilter || undefined,
      });
      if (!result.ok) {
        setError(result.error);
        return;
      }
      setPage(result.page);
      if (!cursor) {
        setSelected(result.page.rows[0] ?? null);
      }
    });
  }

  return (
    <div data-testid="audit-viewer">
      <div
        className="card"
        style={{
          display: 'grid',
          gap: 'var(--space-3)',
          gridTemplateColumns: 'repeat(auto-fit, minmax(11rem, 1fr))',
          marginBottom: 'var(--space-4)',
        }}
      >
        <label style={{ display: 'grid', gap: 'var(--space-1)', fontSize: '0.875rem' }}>
          Action
          <input
            data-testid="audit-filter-action"
            value={actionFilter}
            onChange={(e) => setActionFilter(e.target.value)}
            placeholder="update, insert, rpc:…"
          />
        </label>
        <label style={{ display: 'grid', gap: 'var(--space-1)', fontSize: '0.875rem' }}>
          Target type
          <input
            data-testid="audit-filter-target-type"
            value={targetTypeFilter}
            onChange={(e) => setTargetTypeFilter(e.target.value)}
            placeholder="parks, app_config"
          />
        </label>
        <label style={{ display: 'grid', gap: 'var(--space-1)', fontSize: '0.875rem' }}>
          Actor role
          <input
            data-testid="audit-filter-actor-role"
            value={actorRoleFilter}
            onChange={(e) => setActorRoleFilter(e.target.value)}
            placeholder="ops_lead"
          />
        </label>
        <label style={{ display: 'grid', gap: 'var(--space-1)', fontSize: '0.875rem' }}>
          Target id
          <input
            data-testid="audit-filter-target-id"
            value={targetIdFilter}
            onChange={(e) => setTargetIdFilter(e.target.value)}
            placeholder="entity id"
          />
        </label>
        <div style={{ display: 'flex', alignItems: 'end', gap: 'var(--space-2)' }}>
          <button
            type="button"
            data-testid="audit-apply-filters"
            disabled={pending}
            onClick={() => applyFilters()}
          >
            Apply filters
          </button>
        </div>
      </div>

      {error ? (
        <div className="error-banner" role="alert">
          {error}
        </div>
      ) : null}

      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'minmax(0, 1.2fr) minmax(0, 1fr)',
          gap: 'var(--space-4)',
          alignItems: 'start',
        }}
      >
        <div style={{ overflowX: 'auto' }}>
          <table className="data-table">
            <thead>
              <tr>
                <th>Time</th>
                <th>Action</th>
                <th>Target</th>
                <th>Role</th>
              </tr>
            </thead>
            <tbody>
              {page.rows.length === 0 ? (
                <tr>
                  <td colSpan={4} style={{ padding: 'var(--space-3)', color: 'var(--color-text-muted)' }}>
                    No audit entries match these filters.
                  </td>
                </tr>
              ) : (
                page.rows.map((row) => (
                  <tr
                    key={row.id}
                    data-testid="audit-row"
                    onClick={() => setSelected(row)}
                    style={{
                      cursor: 'pointer',
                      background:
                        selected?.id === row.id ? 'var(--a-accent-tint)' : undefined,
                    }}
                  >
                    <td>
                      {new Date(row.created_at).toLocaleString()}
                    </td>
                    <td>{row.action}</td>
                    <td>
                      <code>
                        {row.target_type}/{shortId(row.target_id)}
                      </code>
                    </td>
                    <td>{row.actor_role?.replace(/_/g, ' ') ?? '—'}</td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
          <div
            style={{
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              marginTop: 'var(--space-3)',
            }}
          >
            <span style={{ fontSize: '0.875rem', color: 'var(--color-text-muted)' }}>
              Showing up to {page.pageSize} rows per page
            </span>
            <button
              type="button"
              data-testid="audit-next-page"
              disabled={pending || page.nextCursor == null}
              onClick={() => applyFilters(page.nextCursor ?? undefined)}
            >
              Next page
            </button>
          </div>
        </div>

        <aside className="card" aria-label="Audit diff" data-testid="audit-diff-panel">
          <h2 className="section-title">Before / after</h2>
          {!selected ? (
            <p style={{ margin: 0, color: 'var(--color-text-muted)', fontSize: '0.875rem' }}>
              Select a row to inspect the JSON diff.
            </p>
          ) : (
            <>
              <p style={{ margin: '0 0 var(--space-3)', fontSize: '0.875rem' }}>
                Audit #{shortId(String(selected.id))}: {selected.action} on{' '}
                <code>
                  {selected.target_type}/{shortId(selected.target_id)}
                </code>
              </p>
              {changedKeys.length > 0 ? (
                <p style={{ margin: '0 0 var(--space-2)', fontSize: '0.8125rem' }}>
                  Changed keys: {changedKeys.join(', ')}
                </p>
              ) : null}
              <div
                style={{
                  display: 'grid',
                  gridTemplateColumns: '1fr 1fr',
                  gap: 'var(--space-2)',
                }}
              >
                <div>
                  <h3 className="sub-title">Before</h3>
                  <pre
                    data-testid="audit-diff-before"
                    style={{
                      margin: 0,
                      padding: 'var(--space-2)',
                      background: 'var(--color-surface-muted, #f4f4f5)',
                      borderRadius: '4px',
                      fontSize: '0.75rem',
                      maxHeight: '24rem',
                      overflow: 'auto',
                      whiteSpace: 'pre-wrap',
                      wordBreak: 'break-word',
                    }}
                  >
                    {formatAuditJson(selected.before)}
                  </pre>
                </div>
                <div>
                  <h3 className="sub-title">After</h3>
                  <pre
                    data-testid="audit-diff-after"
                    style={{
                      margin: 0,
                      padding: 'var(--space-2)',
                      background: 'var(--color-surface-muted, #f4f4f5)',
                      borderRadius: '4px',
                      fontSize: '0.75rem',
                      maxHeight: '24rem',
                      overflow: 'auto',
                      whiteSpace: 'pre-wrap',
                      wordBreak: 'break-word',
                    }}
                  >
                    {formatAuditJson(selected.after)}
                  </pre>
                </div>
              </div>
            </>
          )}
        </aside>
      </div>
    </div>
  );
}
