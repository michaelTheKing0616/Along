'use client';

import { useMemo, useState, useTransition } from 'react';
import type { AuditLogRow } from '@/lib/supabase/server';
import {
  CONFIG_SCOPE_LABELS,
  type ConfigKeyMeta,
  type ConfigScope,
} from '@/lib/config/keys';
import { formatConfigValue, getConfigSchema, parseConfigInput } from '@/lib/config/schemas';
import { setConfigValue } from './actions';

type ScopedValue = {
  key: string;
  scopeType: ConfigScope;
  scopeId: string;
  value: unknown;
  updatedAt: string;
};

interface ConfigEditorProps {
  citySlug: string;
  cityId: string;
  countryCode: string;
  keys: ConfigKeyMeta[];
  scopedValues: ScopedValue[];
  initialAudit: AuditLogRow[];
}

function scopeIdForTab(scope: ConfigScope, cityId: string, countryCode: string): string {
  switch (scope) {
    case 'global':
      return '*';
    case 'country':
      return countryCode;
    case 'city':
      return cityId;
    default:
      return '*';
  }
}

function resolveEffectiveValue(
  key: string,
  scope: ConfigScope,
  scopedValues: ScopedValue[],
  cityId: string,
  countryCode: string
): unknown {
  const order: ConfigScope[] =
    scope === 'corridor'
      ? ['corridor', 'city', 'country', 'global']
      : scope === 'city'
        ? ['city', 'country', 'global']
        : scope === 'country'
          ? ['country', 'global']
          : ['global'];

  for (const layer of order) {
    const scopeId = scopeIdForTab(layer, cityId, countryCode);
    const hit = scopedValues.find(
      (row) => row.key === key && row.scopeType === layer && row.scopeId === scopeId
    );
    if (hit) return hit.value;
  }

  return undefined;
}

export function ConfigEditor({
  citySlug,
  cityId,
  countryCode,
  keys,
  scopedValues,
  initialAudit,
}: ConfigEditorProps) {
  const [selectedKey, setSelectedKey] = useState(keys[0]?.key ?? 'graph.snap_radius_m');
  const [scopeTab, setScopeTab] = useState<ConfigScope>('global');
  const [draftValue, setDraftValue] = useState(() => {
    const key = keys[0]?.key ?? 'graph.snap_radius_m';
    const row = scopedValues.find(
      (r) => r.key === key && r.scopeType === 'global' && r.scopeId === '*'
    );
    if (row) return formatConfigValue(row.value);
    return '60';
  });
  const [reason, setReason] = useState('');
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [auditRows, setAuditRows] = useState(initialAudit);
  const [pending, startTransition] = useTransition();

  const keyMeta = useMemo(
    () => keys.find((k) => k.key === selectedKey) ?? null,
    [keys, selectedKey]
  );

  const allowedScopes = keyMeta?.allowedScopes ?? ['global'];
  const scopeId = scopeIdForTab(scopeTab, cityId, countryCode);

  const currentScoped = scopedValues.find(
    (row) => row.key === selectedKey && row.scopeType === scopeTab && row.scopeId === scopeId
  );

  const effectiveValue = resolveEffectiveValue(
    selectedKey,
    scopeTab,
    scopedValues,
    cityId,
    countryCode
  );

  const schema = getConfigSchema(selectedKey);
  const parsedDraft = parseConfigInput(selectedKey, draftValue);
  const diffLabel =
    parsedDraft.ok && currentScoped
      ? `${formatConfigValue(currentScoped.value)} → ${formatConfigValue(parsedDraft.value)}`
      : parsedDraft.ok
        ? `(new) → ${formatConfigValue(parsedDraft.value)}`
        : null;

  function onSelectKey(key: string) {
    setSelectedKey(key);
    setMessage(null);
    setError(null);
    const row = scopedValues.find(
      (r) => r.key === key && r.scopeType === scopeTab && r.scopeId === scopeId
    );
    setDraftValue(row ? formatConfigValue(row.value) : formatConfigValue(effectiveValue ?? ''));
  }

  function onScopeChange(scope: ConfigScope) {
    setScopeTab(scope);
    setMessage(null);
    setError(null);
    const id = scopeIdForTab(scope, cityId, countryCode);
    const row = scopedValues.find(
      (r) => r.key === selectedKey && r.scopeType === scope && r.scopeId === id
    );
    const effective = resolveEffectiveValue(selectedKey, scope, scopedValues, cityId, countryCode);
    setDraftValue(row ? formatConfigValue(row.value) : formatConfigValue(effective ?? ''));
  }

  function saveConfig() {
    setMessage(null);
    setError(null);

    if (!reason.trim()) {
      setError('Reason is required.');
      return;
    }

    if (keyMeta?.readOnly) {
      setError('This key is read-only in the admin console.');
      return;
    }

    if (!parsedDraft.ok) {
      setError(parsedDraft.error);
      return;
    }

    startTransition(async () => {
      const result = await setConfigValue({
        citySlug,
        key: selectedKey,
        scopeType: scopeTab,
        scopeId,
        value: parsedDraft.value,
        reason: reason.trim(),
      });

      if (result.ok) {
        setMessage(result.message);
        setAuditRows((rows) => [
          {
            id: Date.now(),
            actor_id: null,
            actor_role: 'superadmin',
            action: 'update',
            target_type: 'app_config',
            target_id: `${selectedKey}:${scopeTab}:${scopeId}`,
            before: null,
            after: null,
            created_at: new Date().toISOString(),
          },
          ...rows,
        ]);
        setReason('');
      } else {
        setError(result.error);
      }
    });
  }

  return (
    <div data-testid="config-editor">
      {error ? (
        <div className="error-banner" role="alert">
          {error}
        </div>
      ) : null}
      {message ? (
        <div className="card" role="status" data-testid="config-success" style={{ marginBottom: 'var(--space-4)' }}>
          {message}
        </div>
      ) : null}

      <div style={{ display: 'grid', gridTemplateColumns: '240px 1fr', gap: 'var(--space-6)' }}>
        <aside>
          <h2 style={{ fontSize: '1rem', margin: '0 0 var(--space-3)' }}>Config keys</h2>
          <ul style={{ listStyle: 'none', padding: 0, margin: 0 }}>
            {keys.map((key) => (
              <li key={key.key} style={{ marginBottom: 'var(--space-1)' }}>
                <button
                  type="button"
                  className="tree-button"
                  data-testid={`config-key-${key.key}`}
                  onClick={() => onSelectKey(key.key)}
                  style={{
                    fontWeight: selectedKey === key.key ? 600 : 400,
                    width: '100%',
                    textAlign: 'left',
                  }}
                >
                  {key.key}
                  {key.readOnly ? ' (read-only)' : ''}
                </button>
              </li>
            ))}
          </ul>
        </aside>

        <section className="card">
          <h2 style={{ fontSize: '1rem', margin: '0 0 var(--space-2)' }}>{selectedKey}</h2>
          {keyMeta?.description ? (
            <p style={{ margin: '0 0 var(--space-4)', color: 'var(--color-text-muted)', fontSize: '0.875rem' }}>
              {keyMeta.description}
            </p>
          ) : null}

          <div className="nav-links" style={{ marginBottom: 'var(--space-4)' }} role="tablist">
            {allowedScopes.map((scope) => (
              <button
                key={scope}
                type="button"
                role="tab"
                aria-selected={scopeTab === scope}
                data-testid={`config-scope-${scope}`}
                onClick={() => onScopeChange(scope)}
                style={{
                  border: scopeTab === scope ? '1px solid var(--color-primary)' : '1px solid transparent',
                  background: scopeTab === scope ? 'var(--color-surface-muted)' : 'transparent',
                  padding: 'var(--space-2) var(--space-3)',
                  borderRadius: 'var(--radius-sm)',
                  cursor: 'pointer',
                }}
              >
                {CONFIG_SCOPE_LABELS[scope]}
              </button>
            ))}
          </div>

          <p style={{ fontSize: '0.8125rem', color: 'var(--color-text-muted)' }} data-testid="config-effective-value">
            Effective value at city:{' '}
            <code>{formatConfigValue(effectiveValue ?? '(unset)')}</code>
          </p>

          <div className="field">
            <label htmlFor="config-value">Value at {CONFIG_SCOPE_LABELS[scopeTab]} scope</label>
            {schema?.type === 'boolean' ? (
              <select
                id="config-value"
                value={draftValue}
                onChange={(e) => setDraftValue(e.target.value)}
                data-testid="config-value-input"
                disabled={keyMeta?.readOnly}
              >
                <option value="true">true</option>
                <option value="false">false</option>
              </select>
            ) : (
              <input
                id="config-value"
                value={draftValue}
                onChange={(e) => setDraftValue(e.target.value)}
                data-testid="config-value-input"
                disabled={keyMeta?.readOnly}
              />
            )}
          </div>

          {diffLabel ? (
            <p style={{ fontSize: '0.8125rem' }} data-testid="config-diff">
              Diff: <code>{diffLabel}</code>
            </p>
          ) : null}

          <div className="field">
            <label htmlFor="config-reason">Reason (required)</label>
            <input
              id="config-reason"
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              data-testid="config-reason"
              placeholder="Why is this change needed?"
            />
          </div>

          <button
            type="button"
            className="btn btn-primary"
            data-testid="config-save"
            disabled={pending || keyMeta?.readOnly}
            onClick={saveConfig}
          >
            Save config
          </button>
        </section>
      </div>

      <section className="card" style={{ marginTop: 'var(--space-6)' }}>
        <h2 style={{ fontSize: '1rem', margin: '0 0 var(--space-3)' }}>Recent audit history</h2>
        {auditRows.length === 0 ? (
          <p style={{ color: 'var(--color-text-muted)', fontSize: '0.875rem' }}>No audit rows yet.</p>
        ) : (
          <ul style={{ listStyle: 'none', padding: 0, margin: 0 }} data-testid="config-audit-history">
            {auditRows.slice(0, 8).map((row) => (
              <li key={row.id} style={{ fontSize: '0.8125rem', marginBottom: 'var(--space-2)' }}>
                <code>{row.target_id}</code> — {row.action} by {row.actor_role ?? 'unknown'} at{' '}
                {new Date(row.created_at).toLocaleString()}
              </li>
            ))}
          </ul>
        )}
      </section>
    </div>
  );
}
