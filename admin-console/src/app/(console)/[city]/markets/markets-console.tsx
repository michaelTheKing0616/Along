'use client';

import { useMemo, useState, useTransition } from 'react';
import { ghanaHypotheticalForm } from '@/lib/markets/payload';
import type {
  CountryFormInput,
  CountryRow,
  DeploymentOption,
  I18nCoverageRow,
  MarketsTab,
  PaymentProvider,
  VerificationDocRow,
} from '@/lib/markets/types';
import {
  setCountrySchema,
  updateCountryFlags,
  updatePaymentProvider,
  upsertCountry,
} from './actions';

interface MarketsConsoleProps {
  citySlug: string;
  countries: CountryRow[];
  deployments: DeploymentOption[];
  i18nCoverage: I18nCoverageRow[];
}

const TABS: { id: MarketsTab; label: string }[] = [
  { id: 'countries', label: 'Countries' },
  { id: 'verification', label: 'Verification schema' },
  { id: 'regulatory', label: 'Regulatory flags' },
  { id: 'i18n', label: 'i18n coverage' },
  { id: 'payment', label: 'Payment provider' },
];

const PAYMENT_PROVIDERS: PaymentProvider[] = ['paystack', 'flutterwave', 'none'];

function countryToForm(row: CountryRow): CountryFormInput {
  return {
    code: row.code,
    name: row.name,
    currency_code: row.currency_code,
    currency_symbol: row.currency_symbol,
    currency_minor_units: row.currency_minor_units,
    phone_prefix: row.phone_prefix,
    default_locale: row.default_locale,
    timezone: row.timezone,
    deployment_id: row.deployment_id,
    active: row.active,
    women_only_matching: Boolean(row.regulatory_flags.women_only_matching),
    payment_provider: row.payment_provider,
    verification_schema:
      row.verification_schema.length > 0
        ? row.verification_schema
        : [{ type: '', label: '', pattern: '', provider: 'verifyme' }],
  };
}

function emptyDocRow(): VerificationDocRow {
  return { type: '', label: '', pattern: '', provider: 'verifyme' };
}

export function MarketsConsole({
  citySlug,
  countries: initialCountries,
  deployments,
  i18nCoverage,
}: MarketsConsoleProps) {
  const [tab, setTab] = useState<MarketsTab>('countries');
  const [countries, setCountries] = useState(initialCountries);
  const [selectedCode, setSelectedCode] = useState(initialCountries[0]?.code ?? '');
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [pending, startTransition] = useTransition();

  const defaultDeploymentId = deployments[0]?.id ?? '';
  const [newCountry, setNewCountry] = useState<CountryFormInput>(() =>
    ghanaHypotheticalForm(defaultDeploymentId)
  );

  const selectedCountry = useMemo(
    () => countries.find((c) => c.code === selectedCode) ?? null,
    [countries, selectedCode]
  );

  const [editForm, setEditForm] = useState<CountryFormInput | null>(() =>
    selectedCountry ? countryToForm(selectedCountry) : null
  );

  function syncEditForm(code: string) {
    const row = countries.find((c) => c.code === code);
    setSelectedCode(code);
    setEditForm(row ? countryToForm(row) : null);
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

  function patchCountrySaved(form: CountryFormInput) {
    setCountries((prev) => {
      const next: CountryRow = {
        code: form.code.toUpperCase(),
        name: form.name,
        currency_code: form.currency_code,
        currency_minor_units: form.currency_minor_units,
        currency_symbol: form.currency_symbol,
        phone_prefix: form.phone_prefix,
        default_locale: form.default_locale,
        timezone: form.timezone,
        deployment_id: form.deployment_id,
        verification_schema: form.verification_schema.filter((d) => d.type.trim()),
        regulatory_flags: { women_only_matching: form.women_only_matching },
        active: form.active,
        payment_provider: form.payment_provider,
      };
      const idx = prev.findIndex((c) => c.code === next.code);
      if (idx >= 0) {
        const copy = [...prev];
        copy[idx] = next;
        return copy.sort((a, b) => a.code.localeCompare(b.code));
      }
      return [...prev, next].sort((a, b) => a.code.localeCompare(b.code));
    });
    syncEditForm(form.code.toUpperCase());
  }

  function updateDocRow(index: number, patch: Partial<VerificationDocRow>) {
    if (!editForm) return;
    const schema = editForm.verification_schema.map((row, i) =>
      i === index ? { ...row, ...patch } : row
    );
    setEditForm({ ...editForm, verification_schema: schema });
  }

  return (
    <div data-testid="markets-console">
      {error ? (
        <div className="error-banner" role="alert" data-testid="markets-error">
          {error}
        </div>
      ) : null}
      {message ? (
        <div
          className="card"
          role="status"
          data-testid="markets-success"
          style={{
            marginBottom: 'var(--space-4)',
            borderColor: 'var(--color-brand-yellow)',
            fontSize: '0.875rem',
          }}
        >
          {message}
        </div>
      ) : null}

      <div
        className="nav-links"
        role="tablist"
        aria-label="Markets & portability"
        style={{ marginBottom: 'var(--space-4)' }}
      >
        {TABS.map(({ id, label }) => (
          <button
            key={id}
            type="button"
            role="tab"
            aria-selected={tab === id}
            className={tab === id ? 'nav-link-active' : undefined}
            onClick={() => setTab(id)}
            data-testid={`markets-tab-${id}`}
          >
            {label}
          </button>
        ))}
      </div>

      {tab === 'countries' ? (
        <section aria-label="Countries" data-testid="markets-countries">
          <table className="data-table">
            <thead>
              <tr>
                <th>Code</th>
                <th>Name</th>
                <th>Currency</th>
                <th>Phone</th>
                <th>Locale</th>
                <th>Timezone</th>
                <th>Active</th>
              </tr>
            </thead>
            <tbody>
              {countries.map((row) => (
                <tr key={row.code} data-testid={`country-row-${row.code}`}>
                  <td>{row.code}</td>
                  <td>{row.name}</td>
                  <td>
                    {row.currency_symbol} {row.currency_code}
                  </td>
                  <td>{row.phone_prefix}</td>
                  <td>{row.default_locale}</td>
                  <td>{row.timezone}</td>
                  <td>{row.active ? 'Yes' : 'No'}</td>
                </tr>
              ))}
            </tbody>
          </table>

          <div className="card" style={{ marginTop: 'var(--space-6)' }}>
            <h2 style={{ marginTop: 0, fontSize: '1rem' }}>Add hypothetical country (config-only)</h2>
            <p style={{ color: 'var(--color-text-muted)', fontSize: '0.875rem' }}>
              Example: Ghana (GH) — writes <code>countries</code>, verification schema, regulatory
              flags, and country-scoped <code>payments.provider</code>. No app code changes.
            </p>
            <div className="field">
              <label htmlFor="markets-new-code">Country code</label>
              <input
                id="markets-new-code"
                data-testid="markets-new-code"
                value={newCountry.code}
                onChange={(e) => setNewCountry({ ...newCountry, code: e.target.value.toUpperCase() })}
                maxLength={2}
              />
            </div>
            <div className="field">
              <label htmlFor="markets-new-name">Name</label>
              <input
                id="markets-new-name"
                data-testid="markets-new-name"
                value={newCountry.name}
                onChange={(e) => setNewCountry({ ...newCountry, name: e.target.value })}
              />
            </div>
            <div className="field">
              <label htmlFor="markets-new-currency">Currency code</label>
              <input
                id="markets-new-currency"
                data-testid="markets-new-currency"
                value={newCountry.currency_code}
                onChange={(e) =>
                  setNewCountry({ ...newCountry, currency_code: e.target.value.toUpperCase() })
                }
              />
            </div>
            <div className="field">
              <label htmlFor="markets-new-symbol">Currency symbol</label>
              <input
                id="markets-new-symbol"
                data-testid="markets-new-symbol"
                value={newCountry.currency_symbol}
                onChange={(e) => setNewCountry({ ...newCountry, currency_symbol: e.target.value })}
              />
            </div>
            <div className="field">
              <label htmlFor="markets-new-phone">Phone prefix</label>
              <input
                id="markets-new-phone"
                data-testid="markets-new-phone"
                value={newCountry.phone_prefix}
                onChange={(e) => setNewCountry({ ...newCountry, phone_prefix: e.target.value })}
              />
            </div>
            <div className="field">
              <label htmlFor="markets-new-locale">Default locale</label>
              <input
                id="markets-new-locale"
                data-testid="markets-new-locale"
                value={newCountry.default_locale}
                onChange={(e) => setNewCountry({ ...newCountry, default_locale: e.target.value })}
              />
            </div>
            <div className="field">
              <label htmlFor="markets-new-timezone">Timezone</label>
              <input
                id="markets-new-timezone"
                data-testid="markets-new-timezone"
                value={newCountry.timezone}
                onChange={(e) => setNewCountry({ ...newCountry, timezone: e.target.value })}
              />
            </div>
            <div className="field">
              <label htmlFor="markets-new-deployment">Deployment</label>
              <select
                id="markets-new-deployment"
                data-testid="markets-new-deployment"
                value={newCountry.deployment_id}
                onChange={(e) => setNewCountry({ ...newCountry, deployment_id: e.target.value })}
              >
                {deployments.map((d) => (
                  <option key={d.id} value={d.id}>
                    {d.tenant_name}
                  </option>
                ))}
              </select>
            </div>
            <div className="field">
              <label htmlFor="markets-new-active">
                <input
                  id="markets-new-active"
                  type="checkbox"
                  data-testid="markets-new-active"
                  checked={newCountry.active}
                  onChange={(e) => setNewCountry({ ...newCountry, active: e.target.checked })}
                />{' '}
                Active (shown in phone country picker)
              </label>
            </div>
            <button
              type="button"
              className="btn btn-primary"
              disabled={pending}
              data-testid="markets-save-country"
              onClick={() =>
                runAction(async () => {
                  const result = await upsertCountry(citySlug, newCountry);
                  if (result.ok) patchCountrySaved(newCountry);
                  return result;
                })
              }
            >
              Save country config
            </button>
            <button
              type="button"
              className="btn"
              style={{ marginLeft: 'var(--space-2)' }}
              data-testid="markets-prefill-ghana"
              onClick={() => setNewCountry(ghanaHypotheticalForm(defaultDeploymentId))}
            >
              Prefill Ghana (GH)
            </button>
          </div>
        </section>
      ) : null}

      {tab === 'verification' ? (
        <section aria-label="Verification schema" data-testid="markets-verification">
          <div className="field">
            <label htmlFor="markets-verification-country">Country</label>
            <select
              id="markets-verification-country"
              data-testid="markets-verification-country"
              value={selectedCode}
              onChange={(e) => syncEditForm(e.target.value)}
            >
              {countries.map((c) => (
                <option key={c.code} value={c.code}>
                  {c.code} — {c.name}
                </option>
              ))}
            </select>
          </div>
          {editForm ? (
            <>
              {editForm.verification_schema.map((doc, index) => (
                <div key={index} className="card" style={{ marginBottom: 'var(--space-3)' }}>
                  <div className="field">
                    <label htmlFor={`markets-doc-type-${index}`}>Document type</label>
                    <input
                      id={`markets-doc-type-${index}`}
                      data-testid={`markets-doc-type-${index}`}
                      value={doc.type}
                      onChange={(e) => updateDocRow(index, { type: e.target.value })}
                    />
                  </div>
                  <div className="field">
                    <label htmlFor={`markets-doc-label-${index}`}>Label</label>
                    <input
                      id={`markets-doc-label-${index}`}
                      data-testid={`markets-doc-label-${index}`}
                      value={doc.label}
                      onChange={(e) => updateDocRow(index, { label: e.target.value })}
                    />
                  </div>
                  <div className="field">
                    <label htmlFor={`markets-doc-pattern-${index}`}>Pattern</label>
                    <input
                      id={`markets-doc-pattern-${index}`}
                      data-testid={`markets-doc-pattern-${index}`}
                      value={doc.pattern}
                      onChange={(e) => updateDocRow(index, { pattern: e.target.value })}
                    />
                  </div>
                  <div className="field">
                    <label htmlFor={`markets-doc-provider-${index}`}>Provider</label>
                    <input
                      id={`markets-doc-provider-${index}`}
                      data-testid={`markets-doc-provider-${index}`}
                      value={doc.provider}
                      onChange={(e) => updateDocRow(index, { provider: e.target.value })}
                    />
                  </div>
                </div>
              ))}
              <button
                type="button"
                className="btn"
                data-testid="markets-add-doc-row"
                onClick={() =>
                  setEditForm({
                    ...editForm,
                    verification_schema: [...editForm.verification_schema, emptyDocRow()],
                  })
                }
              >
                Add document type
              </button>{' '}
              <button
                type="button"
                className="btn btn-primary"
                disabled={pending}
                data-testid="markets-save-schema"
                onClick={() =>
                  runAction(async () => {
                    const schema = editForm.verification_schema.filter((d) => d.type.trim());
                    const result = await setCountrySchema(citySlug, editForm.code, schema);
                    if (result.ok) {
                      patchCountrySaved({ ...editForm, verification_schema: schema });
                    }
                    return result;
                  })
                }
              >
                Save verification schema
              </button>
            </>
          ) : (
            <p style={{ color: 'var(--color-text-muted)' }}>Select a country to edit its schema.</p>
          )}
        </section>
      ) : null}

      {tab === 'regulatory' ? (
        <section aria-label="Regulatory flags" data-testid="markets-regulatory">
          <div className="field">
            <label htmlFor="markets-regulatory-country">Country</label>
            <select
              id="markets-regulatory-country"
              data-testid="markets-regulatory-country"
              value={selectedCode}
              onChange={(e) => syncEditForm(e.target.value)}
            >
              {countries.map((c) => (
                <option key={c.code} value={c.code}>
                  {c.code} — {c.name}
                </option>
              ))}
            </select>
          </div>
          {editForm ? (
            <>
              <div className="field">
                <label htmlFor="markets-women-only">
                  <input
                    id="markets-women-only"
                    type="checkbox"
                    data-testid="markets-women-only"
                    checked={editForm.women_only_matching}
                    onChange={(e) =>
                      setEditForm({ ...editForm, women_only_matching: e.target.checked })
                    }
                  />{' '}
                  women_only_matching (gates request/hail when enabled)
                </label>
              </div>
              <button
                type="button"
                className="btn btn-primary"
                disabled={pending}
                data-testid="markets-save-regulatory"
                onClick={() =>
                  runAction(async () => {
                    const result = await updateCountryFlags(citySlug, editForm);
                    if (result.ok) patchCountrySaved(editForm);
                    return result;
                  })
                }
              >
                Save regulatory flags
              </button>
            </>
          ) : null}
        </section>
      ) : null}

      {tab === 'i18n' ? (
        <section aria-label="i18n coverage" data-testid="markets-i18n">
          <p style={{ color: 'var(--color-text-muted)', fontSize: '0.875rem' }}>
            Static coverage from packaged ARB keys (rider + driver union). Locale packs are P10-B-01.
          </p>
          <table className="data-table">
            <thead>
              <tr>
                <th>Locale</th>
                <th>Translated</th>
                <th>Total keys</th>
                <th>Coverage</th>
                <th>Source</th>
              </tr>
            </thead>
            <tbody>
              {i18nCoverage.map((row) => (
                <tr key={row.locale} data-testid={`i18n-row-${row.locale}`}>
                  <td>{row.locale}</td>
                  <td>{row.translated_keys}</td>
                  <td>{row.total_keys}</td>
                  <td>{row.coverage_pct}%</td>
                  <td>{row.source}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </section>
      ) : null}

      {tab === 'payment' ? (
        <section aria-label="Payment provider" data-testid="markets-payment">
          <p style={{ color: 'var(--color-text-muted)', fontSize: '0.875rem' }}>
            Country-scoped <code>payments.provider</code> — does not flip{' '}
            <code>payments.digital_enabled</code>.
          </p>
          <table className="data-table">
            <thead>
              <tr>
                <th>Country</th>
                <th>Currency</th>
                <th>Provider</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {countries.map((row) => (
                <tr key={row.code} data-testid={`payment-row-${row.code}`}>
                  <td>
                    {row.code} — {row.name}
                  </td>
                  <td>{row.currency_code}</td>
                  <td>
                    <select
                      data-testid={`markets-payment-provider-${row.code}`}
                      value={row.payment_provider}
                      onChange={(e) => {
                        const provider = e.target.value as PaymentProvider;
                        setCountries((prev) =>
                          prev.map((c) =>
                            c.code === row.code ? { ...c, payment_provider: provider } : c
                          )
                        );
                        if (editForm?.code === row.code) {
                          setEditForm({ ...editForm, payment_provider: provider });
                        }
                      }}
                    >
                      {PAYMENT_PROVIDERS.map((p) => (
                        <option key={p} value={p}>
                          {p}
                        </option>
                      ))}
                    </select>
                  </td>
                  <td>
                    <button
                      type="button"
                      disabled={pending}
                      data-testid={`markets-save-payment-${row.code}`}
                      onClick={() => {
                        const form = countryToForm({
                          ...row,
                          payment_provider:
                            countries.find((c) => c.code === row.code)?.payment_provider ??
                            row.payment_provider,
                        });
                        runAction(async () => {
                          const result = await updatePaymentProvider(citySlug, form);
                          if (result.ok) patchCountrySaved(form);
                          return result;
                        });
                      }}
                    >
                      Save
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </section>
      ) : null}
    </div>
  );
}
