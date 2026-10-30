'use client';

import { useState, useTransition } from 'react';
import type { AdminRole } from '@/lib/authz/roles';
import { ADMIN_ROLES } from '@/lib/authz/roles';
import type { AdminUserRow, CityScopeOption, DeploymentOption } from '@/lib/admins/types';
import { disableAdmin, inviteAdmin, loadAdminPage, updateAdmin } from './actions';

interface AdminsConsoleProps {
  citySlug: string;
  initialRows: AdminUserRow[];
  initialNextCursor: string | null;
  deployments: DeploymentOption[];
  cities: CityScopeOption[];
}

function totpStatusLabel(row: AdminUserRow): string {
  if (!row.totp_required) return 'Not required';
  return row.totp_enrolled ? 'Enrolled' : 'Required, missing';
}

export function AdminsConsole({
  citySlug,
  initialRows,
  initialNextCursor,
  deployments,
  cities,
}: AdminsConsoleProps) {
  const [rows, setRows] = useState(initialRows);
  const [nextCursor, setNextCursor] = useState<string | null>(initialNextCursor);
  const [selectedId, setSelectedId] = useState<string | null>(initialRows[0]?.id ?? null);
  const [inviteEmail, setInviteEmail] = useState('');
  const [inviteName, setInviteName] = useState('');
  const [inviteRole, setInviteRole] = useState<AdminRole>('ops_agent');
  const [inviteDeploymentId, setInviteDeploymentId] = useState(deployments[0]?.id ?? '');
  const [editRole, setEditRole] = useState<AdminRole>('ops_agent');
  const [editDeploymentId, setEditDeploymentId] = useState('');
  const [editCityScope, setEditCityScope] = useState<string[]>([]);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [pending, startTransition] = useTransition();

  const selected = rows.find((row) => row.id === selectedId) ?? null;

  function syncEditFromRow(row: AdminUserRow) {
    setSelectedId(row.id);
    setEditRole(row.role as AdminRole);
    setEditDeploymentId(row.deployment_id ?? '');
    setEditCityScope(row.city_scope ?? []);
  }

  function runAction(action: () => Promise<{ ok: boolean; message?: string; error?: string; temporaryPassword?: string }>) {
    setMessage(null);
    setError(null);
    startTransition(async () => {
      const result = await action();
      if (result.ok) {
        let text = result.message ?? 'Done.';
        if (result.temporaryPassword) {
          text += ` Temporary password (share securely): ${result.temporaryPassword}`;
        }
        setMessage(text);
        const refreshed = await loadAdminPage({});
        if (refreshed.ok) {
          setRows(refreshed.rows);
          setNextCursor(refreshed.nextCursor);
          const hit = refreshed.rows.find((r) => r.id === selectedId);
          if (hit) syncEditFromRow(hit);
        }
      } else {
        setError(result.error ?? 'Action failed.');
      }
    });
  }

  function loadMore() {
    if (!nextCursor) return;
    startTransition(async () => {
      const result = await loadAdminPage({ cursor: nextCursor });
      if (!result.ok) {
        setError(result.error);
        return;
      }
      setRows((prev) => [...prev, ...result.rows]);
      setNextCursor(result.nextCursor);
    });
  }

  function toggleCityScope(cityId: string) {
    setEditCityScope((prev) =>
      prev.includes(cityId) ? prev.filter((id) => id !== cityId) : [...prev, cityId]
    );
  }

  return (
    <div data-testid="admins-console">
      {message ? (
        <p data-testid="admins-success" style={{ color: 'var(--color-success, #15803d)' }}>
          {message}
        </p>
      ) : null}
      {error ? (
        <div className="error-banner" role="alert">
          {error}
        </div>
      ) : null}

      <section className="card" style={{ marginBottom: 'var(--space-4)' }}>
        <h2 className="section-title">Invite admin</h2>
        <div
          style={{
            display: 'grid',
            gap: 'var(--space-3)',
            gridTemplateColumns: 'repeat(auto-fit, minmax(12rem, 1fr))',
          }}
        >
          <label style={{ display: 'grid', gap: 'var(--space-1)', fontSize: '0.875rem' }}>
            Email
            <input
              data-testid="admins-invite-email"
              type="email"
              value={inviteEmail}
              onChange={(e) => setInviteEmail(e.target.value)}
            />
          </label>
          <label style={{ display: 'grid', gap: 'var(--space-1)', fontSize: '0.875rem' }}>
            Display name
            <input
              data-testid="admins-invite-name"
              value={inviteName}
              onChange={(e) => setInviteName(e.target.value)}
            />
          </label>
          <label style={{ display: 'grid', gap: 'var(--space-1)', fontSize: '0.875rem' }}>
            Role
            <select
              data-testid="admins-invite-role"
              value={inviteRole}
              onChange={(e) => setInviteRole(e.target.value as AdminRole)}
            >
              {ADMIN_ROLES.map((role) => (
                <option key={role} value={role}>
                  {role}
                </option>
              ))}
            </select>
          </label>
          <label style={{ display: 'grid', gap: 'var(--space-1)', fontSize: '0.875rem' }}>
            Deployment
            <select
              data-testid="admins-invite-deployment"
              value={inviteDeploymentId}
              onChange={(e) => setInviteDeploymentId(e.target.value)}
            >
              <option value="">None</option>
              {deployments.map((d) => (
                <option key={d.id} value={d.id}>
                  {d.tenant_name}
                </option>
              ))}
            </select>
          </label>
        </div>
        <button
          type="button"
          data-testid="admins-invite-submit"
          disabled={pending || !inviteEmail.trim()}
          style={{ marginTop: 'var(--space-3)' }}
          onClick={() =>
            runAction(() =>
              inviteAdmin({
                citySlug,
                email: inviteEmail.trim(),
                role: inviteRole,
                deploymentId: inviteDeploymentId || null,
                cityScope: [],
                displayName: inviteName.trim(),
              })
            )
          }
        >
          Send invite
        </button>
      </section>

      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'minmax(0, 1.4fr) minmax(0, 1fr)',
          gap: 'var(--space-4)',
          alignItems: 'start',
        }}
      >
        <div style={{ overflowX: 'auto' }}>
          <table className="data-table">
            <thead>
              <tr>
                <th>Email</th>
                <th>Role</th>
                <th>Deployment</th>
                <th>TOTP</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr
                  key={row.id}
                  data-testid="admin-user-row"
                  onClick={() => syncEditFromRow(row)}
                  style={{
                    cursor: 'pointer',
                    background:
                      selectedId === row.id ? 'var(--a-accent-tint)' : undefined,
                  }}
                >
                  <td>{row.email ?? row.id}</td>
                  <td>{row.role.replace(/_/g, ' ')}</td>
                  <td>
                    {row.deployment_name ?? row.deployment_id ?? '—'}
                  </td>
                  <td data-testid="admin-totp-status">
                    {totpStatusLabel(row)}
                  </td>
                  <td>
                    {row.disabled_at ? 'Disabled' : 'Active'}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          <button
            type="button"
            data-testid="admins-next-page"
            disabled={pending || !nextCursor}
            style={{ marginTop: 'var(--space-3)' }}
            onClick={loadMore}
          >
            Load more
          </button>
        </div>

        <aside className="card" aria-label="Admin detail">
          <h2 className="section-title">Role & scope</h2>
          {!selected ? (
            <p style={{ color: 'var(--color-text-muted)', fontSize: '0.875rem' }}>
              Select an admin to edit role, deployment, or city scope.
            </p>
          ) : (
            <>
              <p style={{ fontSize: '0.875rem', marginTop: 0 }}>
                {selected.email} · TOTP: {totpStatusLabel(selected)}
              </p>
              <label style={{ display: 'grid', gap: 'var(--space-1)', fontSize: '0.875rem' }}>
                Role
                <select
                  data-testid="admins-edit-role"
                  value={editRole}
                  onChange={(e) => setEditRole(e.target.value as AdminRole)}
                >
                  {ADMIN_ROLES.map((role) => (
                    <option key={role} value={role}>
                      {role}
                    </option>
                  ))}
                </select>
              </label>
              <label
                style={{
                  display: 'grid',
                  gap: 'var(--space-1)',
                  fontSize: '0.875rem',
                  marginTop: 'var(--space-3)',
                }}
              >
                Deployment
                <select
                  data-testid="admins-edit-deployment"
                  value={editDeploymentId}
                  onChange={(e) => setEditDeploymentId(e.target.value)}
                >
                  <option value="">None</option>
                  {deployments.map((d) => (
                    <option key={d.id} value={d.id}>
                      {d.tenant_name}
                    </option>
                  ))}
                </select>
              </label>
              <fieldset style={{ marginTop: 'var(--space-3)', border: 'none', padding: 0 }}>
                <legend style={{ fontSize: '0.875rem', marginBottom: 'var(--space-2)' }}>
                  City scope (empty = all cities in deployment)
                </legend>
                <div style={{ display: 'grid', gap: 'var(--space-1)' }}>
                  {cities.map((city) => (
                    <label key={city.id} style={{ fontSize: '0.875rem' }}>
                      <input
                        type="checkbox"
                        data-testid={`admins-city-scope-${city.slug}`}
                        checked={editCityScope.includes(city.id)}
                        onChange={() => toggleCityScope(city.id)}
                      />{' '}
                      {city.name}
                    </label>
                  ))}
                </div>
              </fieldset>
              <div style={{ display: 'flex', gap: 'var(--space-2)', marginTop: 'var(--space-4)' }}>
                <button
                  type="button"
                  data-testid="admins-save"
                  disabled={pending}
                  onClick={() =>
                    runAction(() =>
                      updateAdmin({
                        citySlug,
                        userId: selected.id,
                        role: editRole,
                        deploymentId: editDeploymentId || null,
                        cityScope: editCityScope,
                      })
                    )
                  }
                >
                  Save changes
                </button>
                <button
                  type="button"
                  data-testid="admins-disable"
                  disabled={pending || Boolean(selected.disabled_at)}
                  onClick={() =>
                    runAction(() => disableAdmin({ citySlug, userId: selected.id }))
                  }
                >
                  Disable
                </button>
              </div>
            </>
          )}
        </aside>
      </div>
    </div>
  );
}
