'use client';

import React, { useMemo, useState, useTransition } from 'react';
import { formatMoney } from '@/lib/drivers/format';
import type {
  CorporateAllocationRow,
  CorporateInvoiceRow,
  CorporateMemberRow,
  CorporateOverview,
  CorporatePolicyRow,
  CorporateTab,
} from '@/lib/corporate/types';
import {
  inviteCorporateMember,
  updateCorporateMember,
  upsertCorporatePolicy,
} from './actions';

interface CorporateConsoleProps {
  citySlug: string;
  overview: CorporateOverview | null;
  members: CorporateMemberRow[];
  policies: CorporatePolicyRow[];
  allocations: CorporateAllocationRow[];
  invoices: CorporateInvoiceRow[];
  invoiceLinesByInvoice: Record<string, Array<{ allocation_id: string; amount: number }>>;
  isCorporateAdmin: boolean;
}

const TABS: { id: CorporateTab; label: string }[] = [
  { id: 'overview', label: 'Overview' },
  { id: 'roster', label: 'Roster' },
  { id: 'policies', label: 'Policies' },
  { id: 'history', label: 'Trip history' },
  { id: 'billing', label: 'Billing' },
];

function downloadCsv(filename: string, csv: string) {
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8' });
  const url = URL.createObjectURL(blob);
  const anchor = document.createElement('a');
  anchor.href = url;
  anchor.download = filename;
  anchor.click();
  URL.revokeObjectURL(url);
}

export function CorporateConsole({
  citySlug,
  overview,
  members,
  policies,
  allocations,
  invoices,
  invoiceLinesByInvoice,
  isCorporateAdmin,
}: CorporateConsoleProps) {
  const [tab, setTab] = useState<CorporateTab>('overview');
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [pending, startTransition] = useTransition();

  const [invitePhone, setInvitePhone] = useState('');
  const [inviteDepartment, setInviteDepartment] = useState('');
  const [inviteEmployeeRef, setInviteEmployeeRef] = useState('');
  const [invitePolicyId, setInvitePolicyId] = useState('');

  const [policyName, setPolicyName] = useState('');
  const [policySubsidyPct, setPolicySubsidyPct] = useState('0.5');
  const [policyMaxPerTrip, setPolicyMaxPerTrip] = useState('');
  const [policyHoursJson, setPolicyHoursJson] = useState('');

  const budgetPct = useMemo(() => {
    if (!overview?.monthly_budget || overview.monthly_budget <= 0) return null;
    return (overview.subsidy_used_mtd / overview.monthly_budget) * 100;
  }, [overview]);

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

  function exportTripHistory() {
    if (allocations.length === 0) {
      setError('No allocations to export.');
      return;
    }
    const header = [
      'date',
      'employee_ref',
      'department',
      'mode',
      'fare_shown',
      'subsidy',
      'policy',
    ];
    const lines = allocations.map((row) =>
      [
        row.created_at,
        row.employee_ref ?? '',
        row.department ?? '',
        row.mode_code ?? '',
        row.fare_shown ?? '',
        row.subsidized_amount,
        row.policy_name ?? '',
      ]
        .map((cell) => `"${String(cell).replace(/"/g, '""')}"`)
        .join(',')
    );
    downloadCsv('corporate-trip-history.csv', [header.join(','), ...lines].join('\n'));
    setMessage('Trip history exported.');
  }

  function exportInvoice(invoice: CorporateInvoiceRow) {
    const lines = invoiceLinesByInvoice[invoice.id] ?? [];
    if (lines.length === 0) {
      setError('Invoice has no line items.');
      return;
    }
    const meta = [
      `period_start,${invoice.period_start}`,
      `period_end,${invoice.period_end}`,
      `total,${invoice.total}`,
      `currency,${invoice.currency}`,
      '',
      'allocation_id,amount',
    ];
    const body = lines.map((line) => `${line.allocation_id},${line.amount}`);
    downloadCsv(`invoice-${invoice.id.slice(0, 8)}.csv`, [...meta, ...body].join('\n'));
    setMessage('Invoice downloaded.');
  }

  if (!isCorporateAdmin) {
    return (
      <div className="card" data-testid="corporate-console-unscoped">
        <p>
          Corporate portal data is scoped to a linked corporate account. Sign in as{' '}
          <code>corporate_admin</code> or manage accounts from Revenue.
        </p>
      </div>
    );
  }

  return (
    <div data-testid="corporate-console">
      {error ? (
        <div className="error-banner" role="alert" data-testid="corporate-error">
          {error}
        </div>
      ) : null}
      {message ? (
        <div className="card" role="status" data-testid="corporate-success" style={{ marginBottom: 'var(--space-4)' }}>
          {message}
        </div>
      ) : null}

      <div
        className="seg"
        role="tablist"
        aria-label="Corporate portal sections"
        style={{ marginBottom: 'var(--space-4)' }}
      >
        {TABS.map(({ id, label }) => (
          <button
            key={id}
            type="button"
            role="tab"
            aria-selected={tab === id}
            className={tab === id ? 'nav-link-active' : undefined}
            data-testid={`corporate-tab-${id}`}
            onClick={() => setTab(id)}
          >
            {label}
          </button>
        ))}
      </div>

      {tab === 'overview' ? (
        <section data-testid="corporate-overview">
          <div className="kpi-grid">
            <div className="kpi" data-testid="corporate-subsidy-mtd">
              <div className="kpi-label">Subsidy used MTD</div>
              <p className="kpi-value">
                {formatMoney(overview?.subsidy_used_mtd ?? 0, overview?.currency ?? 'NGN')}
              </p>
              {overview?.monthly_budget != null ? (
                <p className="kpi-sub">
                  Budget {formatMoney(overview.monthly_budget, overview.currency)}
                  {budgetPct != null ? ` · ${budgetPct.toFixed(1)}% used` : null}
                </p>
              ) : null}
            </div>
            <div className="kpi" data-testid="corporate-enrolled-staff">
              <div className="kpi-label">Enrolled staff</div>
              <p className="kpi-value">{overview?.enrolled_staff ?? 0}</p>
            </div>
            <div className="kpi" data-testid="corporate-active-trips">
              <div className="kpi-label">Active staff trips</div>
              <p className="kpi-value">{overview?.live_trips?.length ?? 0}</p>
            </div>
          </div>

          <h2 className="section-title">Live trips</h2>
          {(overview?.live_trips?.length ?? 0) === 0 ? (
            <p className="empty-inline">No staff trips in progress.</p>
          ) : (
            <table className="data-table" data-testid="corporate-live-trips">
              <thead>
                <tr>
                  <th>Employee</th>
                  <th>Department</th>
                  <th>Status</th>
                  <th>Mode</th>
                  <th className="num">Fare</th>
                </tr>
              </thead>
              <tbody>
                {overview?.live_trips.map((trip) => (
                  <tr key={trip.trip_id}>
                    <td>{trip.employee_ref ?? '—'}</td>
                    <td>{trip.department ?? '—'}</td>
                    <td>{trip.status}</td>
                    <td>{trip.mode_code}</td>
                    <td className="num">{formatMoney(trip.fare_shown, overview?.currency ?? 'NGN')}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </section>
      ) : null}

      {tab === 'roster' ? (
        <section data-testid="corporate-roster">
          <h2 className="section-title">Invite staff</h2>
          <div className="field">
            <label htmlFor="corporate-invite-phone">Phone (E.164)</label>
            <input
              id="corporate-invite-phone"
              data-testid="corporate-invite-phone"
              value={invitePhone}
              onChange={(e) => setInvitePhone(e.target.value)}
              placeholder="+2348000000000"
            />
          </div>
          <div className="field">
            <label htmlFor="corporate-invite-department">Department</label>
            <input
              id="corporate-invite-department"
              data-testid="corporate-invite-department"
              value={inviteDepartment}
              onChange={(e) => setInviteDepartment(e.target.value)}
            />
          </div>
          <div className="field">
            <label htmlFor="corporate-invite-ref">Employee ref</label>
            <input
              id="corporate-invite-ref"
              data-testid="corporate-invite-ref"
              value={inviteEmployeeRef}
              onChange={(e) => setInviteEmployeeRef(e.target.value)}
            />
          </div>
          <div className="field">
            <label htmlFor="corporate-invite-policy">Policy</label>
            <select
              id="corporate-invite-policy"
              data-testid="corporate-invite-policy"
              value={invitePolicyId}
              onChange={(e) => setInvitePolicyId(e.target.value)}
            >
              <option value="">Default (best match)</option>
              {policies.filter((p) => p.active).map((p) => (
                <option key={p.id} value={p.id}>
                  {p.name}
                </option>
              ))}
            </select>
          </div>
          <button
            type="button"
            className="btn btn-primary"
            data-testid="corporate-invite-submit"
            disabled={pending || !invitePhone.trim()}
            onClick={() =>
              runAction(() =>
                inviteCorporateMember(citySlug, {
                  phoneE164: invitePhone.trim(),
                  department: inviteDepartment.trim() || undefined,
                  employeeRef: inviteEmployeeRef.trim() || undefined,
                  defaultPolicyId: invitePolicyId || undefined,
                })
              )
            }
          >
            Invite by phone
          </button>

          <h2 className="section-title section-gap">Roster</h2>
          {members.length === 0 ? (
            <p className="empty-inline">No staff enrolled yet.</p>
          ) : (
            <table className="data-table" data-testid="corporate-roster-table">
              <thead>
                <tr>
                  <th>Name</th>
                  <th>Phone</th>
                  <th>Department</th>
                  <th>Policy</th>
                  <th>Status</th>
                  <th />
                </tr>
              </thead>
              <tbody>
                {members.map((member) => (
                  <tr key={member.rider_id} data-testid={`corporate-member-${member.rider_id}`}>
                    <td>{member.display_name ?? member.employee_ref ?? '—'}</td>
                    <td>{member.phone_e164 ?? '—'}</td>
                    <td>{member.department ?? '—'}</td>
                    <td>{member.policy_name ?? '—'}</td>
                    <td>{member.active ? 'Active' : 'Inactive'}</td>
                    <td>
                      <button
                        type="button"
                        className="btn"
                        data-testid={`corporate-member-toggle-${member.rider_id}`}
                        disabled={pending}
                        onClick={() =>
                          runAction(() =>
                            updateCorporateMember(citySlug, {
                              riderId: member.rider_id,
                              active: !member.active,
                            })
                          )
                        }
                      >
                        {member.active ? 'Deactivate' : 'Activate'}
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </section>
      ) : null}

      {tab === 'policies' ? (
        <section data-testid="corporate-policies">
          <h2 className="section-title">Create policy</h2>
          <div className="field">
            <label htmlFor="corporate-policy-name">Name</label>
            <input
              id="corporate-policy-name"
              data-testid="corporate-policy-name"
              value={policyName}
              onChange={(e) => setPolicyName(e.target.value)}
            />
          </div>
          <div className="field">
            <label htmlFor="corporate-policy-subsidy">Subsidy % (0–1)</label>
            <input
              id="corporate-policy-subsidy"
              data-testid="corporate-policy-subsidy"
              type="number"
              step="0.01"
              min="0.01"
              max="1"
              value={policySubsidyPct}
              onChange={(e) => setPolicySubsidyPct(e.target.value)}
            />
          </div>
          <div className="field">
            <label htmlFor="corporate-policy-cap">Cap per trip</label>
            <input
              id="corporate-policy-cap"
              data-testid="corporate-policy-cap"
              type="number"
              value={policyMaxPerTrip}
              onChange={(e) => setPolicyMaxPerTrip(e.target.value)}
            />
          </div>
          <div className="field">
            <label htmlFor="corporate-policy-hours">Allowed hours (JSON)</label>
            <textarea
              id="corporate-policy-hours"
              data-testid="corporate-policy-hours"
              rows={3}
              value={policyHoursJson}
              onChange={(e) => setPolicyHoursJson(e.target.value)}
              placeholder='{"start":"08:00","end":"18:00","days_of_week":[1,2,3,4,5]}'
            />
          </div>
          <button
            type="button"
            className="btn btn-primary"
            data-testid="corporate-policy-submit"
            disabled={pending || !policyName.trim()}
            onClick={() =>
              runAction(() =>
                upsertCorporatePolicy(citySlug, {
                  name: policyName.trim(),
                  subsidyPct: Number(policySubsidyPct),
                  maxPerTrip: policyMaxPerTrip ? Number(policyMaxPerTrip) : null,
                  allowedHoursJson: policyHoursJson,
                })
              )
            }
          >
            Save policy
          </button>

          <h2 className="section-title section-gap">Policies</h2>
          <table className="data-table" data-testid="corporate-policies-table">
            <thead>
              <tr>
                <th>Name</th>
                <th className="num">Subsidy</th>
                <th className="num">Cap</th>
                <th>Hours</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {policies.map((policy) => (
                <tr key={policy.id}>
                  <td>{policy.name}</td>
                  <td className="num">{(policy.subsidy_pct * 100).toFixed(0)}%</td>
                  <td className="num">{policy.max_per_trip != null ? formatMoney(policy.max_per_trip) : '—'}</td>
                  <td>{policy.allowed_hours ? 'Configured' : 'Any'}</td>
                  <td>{policy.active ? 'Active' : 'Inactive'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </section>
      ) : null}

      {tab === 'history' ? (
        <section data-testid="corporate-history">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <h2 className="section-title">Trip allocations</h2>
            <button
              type="button"
              className="btn btn-primary"
              data-testid="corporate-history-export"
              onClick={exportTripHistory}
            >
              Export CSV
            </button>
          </div>
          {allocations.length === 0 ? (
            <p className="empty-inline">No subsidized trips yet.</p>
          ) : (
            <table className="data-table" data-testid="corporate-history-table">
              <thead>
                <tr>
                  <th>Date</th>
                  <th>Employee</th>
                  <th>Department</th>
                  <th>Mode</th>
                  <th className="num">Fare</th>
                  <th className="num">Subsidy</th>
                  <th>Policy</th>
                </tr>
              </thead>
              <tbody>
                {allocations.map((row) => (
                  <tr key={row.id}>
                    <td>{new Date(row.created_at).toLocaleString()}</td>
                    <td>{row.employee_ref ?? '—'}</td>
                    <td>{row.department ?? '—'}</td>
                    <td>{row.mode_code ?? '—'}</td>
                    <td>{row.fare_shown != null ? formatMoney(row.fare_shown) : '—'}</td>
                    <td className="num">{formatMoney(row.subsidized_amount)}</td>
                    <td>{row.policy_name ?? '—'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </section>
      ) : null}

      {tab === 'billing' ? (
        <section data-testid="corporate-billing">
          <h2 className="section-title">Invoices</h2>
          {invoices.length === 0 ? (
            <p className="empty-inline">No invoices generated yet.</p>
          ) : (
            <table className="data-table" data-testid="corporate-invoices-table">
              <thead>
                <tr>
                  <th>Period</th>
                  <th className="num">Total</th>
                  <th>Status</th>
                  <th />
                </tr>
              </thead>
              <tbody>
                {invoices.map((invoice) => (
                  <tr key={invoice.id}>
                    <td>
                      {new Date(invoice.period_start).toLocaleDateString()} –{' '}
                      {new Date(invoice.period_end).toLocaleDateString()}
                    </td>
                    <td className="num">{formatMoney(invoice.total, invoice.currency)}</td>
                    <td>{invoice.status}</td>
                    <td>
                      <button
                        type="button"
                        className="btn"
                        data-testid={`corporate-invoice-download-${invoice.id}`}
                        onClick={() => exportInvoice(invoice)}
                      >
                        Download
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </section>
      ) : null}
    </div>
  );
}
