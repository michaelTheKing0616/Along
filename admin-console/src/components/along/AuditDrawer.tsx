import { fetchAuditLogForTarget } from '@/lib/supabase/server';

interface AuditDrawerProps {
  targetId: string;
  targetLabel?: string;
}

export async function AuditDrawer({ targetId, targetLabel }: AuditDrawerProps) {
  const rows = await fetchAuditLogForTarget(targetId);

  return (
    <aside
      className="card"
      aria-label="Audit history"
      data-testid="audit-drawer"
      style={{ marginTop: 'var(--space-6)' }}
    >
      <h2 style={{ margin: '0 0 var(--space-2)', fontSize: '1rem' }}>
        Audit history
        {targetLabel ? ` — ${targetLabel}` : ''}
      </h2>
      <p style={{ margin: '0 0 var(--space-4)', fontSize: '0.875rem', color: 'var(--color-text-muted)' }}>
        Read-only view of recent changes for target <code>{targetId}</code>.
      </p>
      {rows.length === 0 ? (
        <p style={{ margin: 0, fontSize: '0.875rem', color: 'var(--color-text-muted)' }}>
          No audit entries found for this entity.
        </p>
      ) : (
        <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '0.875rem' }}>
          <thead>
            <tr>
              <th style={{ textAlign: 'left', padding: 'var(--space-2)', borderBottom: '1px solid var(--color-border)' }}>
                Time
              </th>
              <th style={{ textAlign: 'left', padding: 'var(--space-2)', borderBottom: '1px solid var(--color-border)' }}>
                Action
              </th>
              <th style={{ textAlign: 'left', padding: 'var(--space-2)', borderBottom: '1px solid var(--color-border)' }}>
                Role
              </th>
            </tr>
          </thead>
          <tbody>
            {rows.map((row) => (
              <tr key={row.id} data-testid="audit-row">
                <td style={{ padding: 'var(--space-2)', borderBottom: '1px solid var(--color-border)' }}>
                  {new Date(row.created_at).toLocaleString()}
                </td>
                <td style={{ padding: 'var(--space-2)', borderBottom: '1px solid var(--color-border)' }}>
                  {row.action} ({row.target_type})
                </td>
                <td style={{ padding: 'var(--space-2)', borderBottom: '1px solid var(--color-border)' }}>
                  {row.actor_role ?? '—'}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </aside>
  );
}
