'use client';

import { useState, useTransition } from 'react';
import type {
  AnonymizedExportRow,
  ApiKeyRow,
  DeploymentOption,
  RevenueCorporateAccountRow,
  RevenueOperatorAccountRow,
  RevenueTab,
  SponsoredPlacementRow,
} from '@/lib/revenue/types';
import {
  createApiKey,
  createCorporateAccount,
  createOperatorAccount,
  createSponsoredPlacement,
  revokeApiKey,
} from './actions';

interface RevenueConsoleProps {
  citySlug: string;
  deployments: DeploymentOption[];
  placements: SponsoredPlacementRow[];
  apiKeys: ApiKeyRow[];
  corporateAccounts: RevenueCorporateAccountRow[];
  operatorAccounts: RevenueOperatorAccountRow[];
  exports: AnonymizedExportRow[];
  exportK: number;
}

const TABS: { id: RevenueTab; label: string }[] = [
  { id: 'placements', label: 'Sponsored placements' },
  { id: 'api-keys', label: 'API keys' },
  { id: 'accounts', label: 'Accounts' },
  { id: 'exports', label: 'Anonymized exports' },
];

export function RevenueConsole({
  citySlug,
  deployments,
  placements,
  apiKeys,
  corporateAccounts,
  operatorAccounts,
  exports,
  exportK,
}: RevenueConsoleProps) {
  const [tab, setTab] = useState<RevenueTab>('placements');
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [pending, startTransition] = useTransition();
  const [plaintextKey, setPlaintextKey] = useState<string | null>(null);

  const [deploymentId, setDeploymentId] = useState(deployments[0]?.id ?? '');
  const [contextType, setContextType] = useState<'destination' | 'park' | 'corridor'>('park');
  const [targetReference, setTargetReference] = useState('');
  const [advertiser, setAdvertiser] = useState('');
  const [contentJson, setContentJson] = useState('{"headline":"Along partner"}');
  const [activeFrom, setActiveFrom] = useState('');
  const [activeTo, setActiveTo] = useState('');

  const [apiOrg, setApiOrg] = useState('');
  const [apiScopeOd, setApiScopeOd] = useState(true);
  const [apiScopePlacement, setApiScopePlacement] = useState(false);
  const [apiRateLimit, setApiRateLimit] = useState('60');

  const [corpName, setCorpName] = useState('');
  const [corpEmail, setCorpEmail] = useState('');
  const [corpBudget, setCorpBudget] = useState('');

  const [opName, setOpName] = useState('');
  const [opType, setOpType] = useState<'park' | 'union' | 'vehicle_owner' | 'corporate'>('park');

  function runAction(action: () => Promise<{ ok: boolean; message?: string; error?: string; payload?: Record<string, unknown> }>) {
    setMessage(null);
    setError(null);
    setPlaintextKey(null);
    startTransition(async () => {
      const result = await action();
      if (result.ok) {
        setMessage(result.message ?? 'Done.');
        const key = result.payload?.api_key;
        if (typeof key === 'string') {
          setPlaintextKey(key);
        }
      } else {
        setError(result.error ?? 'Action failed.');
      }
    });
  }

  return (
    <div data-testid="revenue-console">
      {error ? (
        <div className="error-banner" role="alert" data-testid="revenue-error">
          {error}
        </div>
      ) : null}
      {message ? (
        <div className="card" role="status" data-testid="revenue-success" style={{ marginBottom: 'var(--space-4)' }}>
          {message}
        </div>
      ) : null}
      {plaintextKey ? (
        <div className="card" data-testid="revenue-api-key-plaintext" style={{ marginBottom: 'var(--space-4)' }}>
          <strong>API key (shown once):</strong>
          <code style={{ display: 'block', marginTop: 'var(--space-2)', wordBreak: 'break-all' }}>
            {plaintextKey}
          </code>
        </div>
      ) : null}

      <div
        className="seg"
        role="tablist"
        aria-label="Revenue hooks"
        style={{ marginBottom: 'var(--space-4)' }}
      >
        {TABS.map(({ id, label }) => (
          <button
            key={id}
            type="button"
            role="tab"
            aria-selected={tab === id}
            className={tab === id ? 'nav-link-active' : undefined}
            data-testid={`revenue-tab-${id}`}
            onClick={() => setTab(id)}
          >
            {label}
          </button>
        ))}
      </div>

      {tab === 'placements' ? (
        <section data-testid="revenue-placements">
          <p style={{ color: 'var(--color-text-muted)' }}>
            Contextual placements only, keyed to destination, park, or corridor. No rider
            targeting.
          </p>
          <div className="field">
            <label htmlFor="revenue-placement-deployment">Deployment</label>
            <select
              id="revenue-placement-deployment"
              data-testid="revenue-placement-deployment"
              value={deploymentId}
              onChange={(e) => setDeploymentId(e.target.value)}
            >
              {deployments.map((d) => (
                <option key={d.id} value={d.id}>
                  {d.tenant_name}
                </option>
              ))}
            </select>
          </div>
          <div className="field">
            <label htmlFor="revenue-placement-context">Context type</label>
            <select
              id="revenue-placement-context"
              data-testid="revenue-placement-context"
              value={contextType}
              onChange={(e) => setContextType(e.target.value as typeof contextType)}
            >
              <option value="destination">Destination</option>
              <option value="park">Park</option>
              <option value="corridor">Corridor</option>
            </select>
          </div>
          <div className="field">
            <label htmlFor="revenue-placement-target">Target reference (UUID)</label>
            <input
              id="revenue-placement-target"
              data-testid="revenue-placement-target"
              value={targetReference}
              onChange={(e) => setTargetReference(e.target.value)}
            />
          </div>
          <div className="field">
            <label htmlFor="revenue-placement-advertiser">Advertiser</label>
            <input
              id="revenue-placement-advertiser"
              data-testid="revenue-placement-advertiser"
              value={advertiser}
              onChange={(e) => setAdvertiser(e.target.value)}
            />
          </div>
          <div className="field">
            <label htmlFor="revenue-placement-content">Content (JSON)</label>
            <textarea
              id="revenue-placement-content"
              data-testid="revenue-placement-content"
              rows={3}
              value={contentJson}
              onChange={(e) => setContentJson(e.target.value)}
            />
          </div>
          <div className="field">
            <label htmlFor="revenue-placement-from">Active from</label>
            <input
              id="revenue-placement-from"
              data-testid="revenue-placement-from"
              type="datetime-local"
              value={activeFrom}
              onChange={(e) => setActiveFrom(e.target.value)}
            />
          </div>
          <div className="field">
            <label htmlFor="revenue-placement-to">Active to</label>
            <input
              id="revenue-placement-to"
              data-testid="revenue-placement-to"
              type="datetime-local"
              value={activeTo}
              onChange={(e) => setActiveTo(e.target.value)}
            />
          </div>
          <button
            type="button"
            className="btn btn-primary"
            data-testid="revenue-placement-submit"
            disabled={pending || !deploymentId || !targetReference.trim() || !advertiser.trim()}
            onClick={() =>
              runAction(() =>
                createSponsoredPlacement(citySlug, {
                  deploymentId,
                  contextType,
                  targetReference: targetReference.trim(),
                  advertiser: advertiser.trim(),
                  contentJson,
                  activeFrom: new Date(activeFrom).toISOString(),
                  activeTo: new Date(activeTo).toISOString(),
                })
              )
            }
          >
            Create placement
          </button>

          <h2 className="section-title section-gap">Placements</h2>
          <table className="data-table" data-testid="revenue-placements-table">
            <thead>
              <tr>
                <th>Advertiser</th>
                <th>Context</th>
                <th>Target</th>
                <th>Schedule</th>
                <th>Impressions</th>
                <th>Taps</th>
              </tr>
            </thead>
            <tbody>
              {placements.map((row) => (
                <tr key={row.id}>
                  <td>{row.advertiser}</td>
                  <td>{row.context_type}</td>
                  <td>{row.target_reference.slice(0, 8)}…</td>
                  <td>
                    {new Date(row.active_from).toLocaleDateString()} –{' '}
                    {new Date(row.active_to).toLocaleDateString()}
                  </td>
                  <td>{row.impressions}</td>
                  <td>{row.taps}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </section>
      ) : null}

      {tab === 'api-keys' ? (
        <section data-testid="revenue-api-keys">
          <div className="field">
            <label htmlFor="revenue-api-org">Owner organization</label>
            <input
              id="revenue-api-org"
              data-testid="revenue-api-org"
              value={apiOrg}
              onChange={(e) => setApiOrg(e.target.value)}
            />
          </div>
          <fieldset className="field">
            <legend>Scope</legend>
            <label>
              <input
                type="checkbox"
                data-testid="revenue-api-scope-od"
                checked={apiScopeOd}
                onChange={(e) => setApiScopeOd(e.target.checked)}
              />{' '}
              od_cells
            </label>
            <label>
              <input
                type="checkbox"
                data-testid="revenue-api-scope-placement"
                checked={apiScopePlacement}
                onChange={(e) => setApiScopePlacement(e.target.checked)}
              />{' '}
              placement_stats
            </label>
          </fieldset>
          <div className="field">
            <label htmlFor="revenue-api-rate">Rate limit / min</label>
            <input
              id="revenue-api-rate"
              data-testid="revenue-api-rate"
              type="number"
              value={apiRateLimit}
              onChange={(e) => setApiRateLimit(e.target.value)}
            />
          </div>
          <button
            type="button"
            className="btn btn-primary"
            data-testid="revenue-api-create"
            disabled={pending || !apiOrg.trim() || (!apiScopeOd && !apiScopePlacement)}
            onClick={() => {
              const scope: string[] = [];
              if (apiScopeOd) scope.push('od_cells');
              if (apiScopePlacement) scope.push('placement_stats');
              runAction(() =>
                createApiKey(citySlug, {
                  ownerOrganization: apiOrg.trim(),
                  scope,
                  rateLimitPerMin: Number(apiRateLimit) || undefined,
                })
              );
            }}
          >
            Create API key
          </button>

          <h2 className="section-title section-gap">Keys</h2>
          <table className="data-table" data-testid="revenue-api-keys-table">
            <thead>
              <tr>
                <th>Organization</th>
                <th>Scope</th>
                <th>Rate</th>
                <th>Usage</th>
                <th>Status</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {apiKeys.map((key) => (
                <tr key={key.id}>
                  <td>{key.owner_organization}</td>
                  <td>{key.scope.join(', ')}</td>
                  <td>{key.rate_limit_per_min}/min</td>
                  <td>{key.total_calls}</td>
                  <td>{key.revoked_at ? 'Revoked' : 'Active'}</td>
                  <td>
                    {!key.revoked_at ? (
                      <button
                        type="button"
                        className="btn"
                        data-testid={`revenue-api-revoke-${key.id}`}
                        disabled={pending}
                        onClick={() => runAction(() => revokeApiKey(citySlug, key.id))}
                      >
                        Revoke
                      </button>
                    ) : null}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </section>
      ) : null}

      {tab === 'accounts' ? (
        <section data-testid="revenue-accounts">
          <h2 className="section-title">Create corporate account</h2>
          <div className="field">
            <label htmlFor="revenue-corp-deployment">Deployment</label>
            <select
              id="revenue-corp-deployment"
              data-testid="revenue-corp-deployment"
              value={deploymentId}
              onChange={(e) => setDeploymentId(e.target.value)}
            >
              {deployments.map((d) => (
                <option key={d.id} value={d.id}>
                  {d.tenant_name}
                </option>
              ))}
            </select>
          </div>
          <div className="field">
            <label htmlFor="revenue-corp-name">Name</label>
            <input
              id="revenue-corp-name"
              data-testid="revenue-corp-name"
              value={corpName}
              onChange={(e) => setCorpName(e.target.value)}
            />
          </div>
          <div className="field">
            <label htmlFor="revenue-corp-email">Billing email</label>
            <input
              id="revenue-corp-email"
              data-testid="revenue-corp-email"
              type="email"
              value={corpEmail}
              onChange={(e) => setCorpEmail(e.target.value)}
            />
          </div>
          <div className="field">
            <label htmlFor="revenue-corp-budget">Monthly budget</label>
            <input
              id="revenue-corp-budget"
              data-testid="revenue-corp-budget"
              type="number"
              value={corpBudget}
              onChange={(e) => setCorpBudget(e.target.value)}
            />
          </div>
          <button
            type="button"
            className="btn btn-primary"
            data-testid="revenue-corp-submit"
            disabled={pending || !corpName.trim() || !corpEmail.trim()}
            onClick={() =>
              runAction(() =>
                createCorporateAccount(citySlug, {
                  deploymentId,
                  name: corpName.trim(),
                  billingEmail: corpEmail.trim(),
                  monthlyBudget: corpBudget ? Number(corpBudget) : undefined,
                })
              )
            }
          >
            Create corporate account
          </button>

          <h2 className="section-title section-gap">Create operator account</h2>
          <div className="field">
            <label htmlFor="revenue-op-name">Name</label>
            <input
              id="revenue-op-name"
              data-testid="revenue-op-name"
              value={opName}
              onChange={(e) => setOpName(e.target.value)}
            />
          </div>
          <div className="field">
            <label htmlFor="revenue-op-type">Type</label>
            <select
              id="revenue-op-type"
              data-testid="revenue-op-type"
              value={opType}
              onChange={(e) => setOpType(e.target.value as typeof opType)}
            >
              <option value="park">Park</option>
              <option value="union">Union</option>
              <option value="vehicle_owner">Vehicle owner</option>
              <option value="corporate">Corporate</option>
            </select>
          </div>
          <button
            type="button"
            className="btn btn-primary"
            data-testid="revenue-op-submit"
            disabled={pending || !opName.trim()}
            onClick={() =>
              runAction(() =>
                createOperatorAccount(citySlug, {
                  deploymentId,
                  type: opType,
                  name: opName.trim(),
                })
              )
            }
          >
            Create operator account
          </button>

          <h2 className="section-title section-gap">Corporate accounts</h2>
          <table className="data-table" data-testid="revenue-corporate-accounts-table">
            <thead>
              <tr>
                <th>Name</th>
                <th>Email</th>
                <th className="num">Budget</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {corporateAccounts.map((row) => (
                <tr key={row.id}>
                  <td>{row.name}</td>
                  <td>{row.billing_email}</td>
                  <td className="num">{row.monthly_budget ?? '—'}</td>
                  <td>{row.status}</td>
                </tr>
              ))}
            </tbody>
          </table>

          <h2 className="section-title section-gap">Operator accounts</h2>
          <table className="data-table" data-testid="revenue-operator-accounts-table">
            <thead>
              <tr>
                <th>Name</th>
                <th>Type</th>
                <th>Tier</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {operatorAccounts.map((row) => (
                <tr key={row.id}>
                  <td>{row.name}</td>
                  <td>{row.type}</td>
                  <td>{row.subscription_tier}</td>
                  <td>{row.billing_status}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </section>
      ) : null}

      {tab === 'exports' ? (
        <section data-testid="revenue-exports">
          <p data-testid="revenue-export-k-threshold">
            k-anonymity threshold (export.k): <strong>{exportK}</strong>
          </p>
          <table className="data-table" data-testid="revenue-exports-table">
            <thead>
              <tr>
                <th>Created</th>
                <th>Period</th>
                <th>k threshold</th>
                <th>Cells emitted</th>
                <th>Suppressed</th>
                <th>Trips examined</th>
              </tr>
            </thead>
            <tbody>
              {exports.map((row) => (
                <tr key={row.id}>
                  <td>{new Date(row.created_at).toLocaleString()}</td>
                  <td>
                    {new Date(row.period_start).toLocaleDateString()} –{' '}
                    {new Date(row.period_end).toLocaleDateString()}
                  </td>
                  <td>{row.k_threshold}</td>
                  <td>{row.cells_emitted}</td>
                  <td>{row.cells_suppressed}</td>
                  <td>{row.trips_examined}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </section>
      ) : null}
    </div>
  );
}
