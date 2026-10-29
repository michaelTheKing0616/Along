import { fetchAuditLogForTarget } from "@/lib/supabase/server";
import { humanize, shortId } from "@/lib/ui/label";

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
      style={{ marginTop: "var(--space-6)" }}
    >
      <h2 className="section-title">
        Audit history
        {targetLabel ? ` · ${targetLabel}` : ""}
      </h2>
      <p
        style={{
          margin: "0 0 var(--space-4)",
          fontSize: "0.875rem",
          color: "var(--color-text-muted)",
        }}
      >
        Recent changes to this record (
        <code title={targetId}>{shortId(targetId)}</code>). Read-only.
      </p>
      {rows.length === 0 ? (
        <p className="empty-inline">No audit entries for this record yet.</p>
      ) : (
        <table className="data-table">
          <thead>
            <tr>
              <th>Time</th>
              <th>Action</th>
              <th>Role</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((row) => (
              <tr key={row.id} data-testid="audit-row">
                <td>{new Date(row.created_at).toLocaleString()}</td>
                <td>
                  {row.action} ({row.target_type})
                </td>
                <td>{humanize(row.actor_role)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </aside>
  );
}
