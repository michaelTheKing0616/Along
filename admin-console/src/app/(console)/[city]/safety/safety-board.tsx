'use client';

import Link from 'next/link';
import { useEffect, useMemo, useState, useTransition, type CSSProperties } from 'react';
import { createClient } from '@/lib/supabase/client';
import {
  formatAgeSeconds,
  formatCoordinates,
  incidentTypeLabel,
  mapExternalUrl,
  parseGeoPoint,
  slaTierForOpenSos,
  slaTierLabel,
} from '@/lib/safety/format';
import type {
  AdminAssignee,
  IncidentQueueRow,
  SafetySlaConfig,
  SlaTier,
  SosBoardRow,
} from '@/lib/safety/types';
import { acknowledgeSos, resolveSos, triageIncident } from './actions';

const RUNBOOK_PATH = '/docs/runbooks/sos_escalation.md';

interface SafetyBoardProps {
  citySlug: string;
  cityId: string;
  initialSosRows: SosBoardRow[];
  initialIncidentRows: IncidentQueueRow[];
  initialSelectedSosId: string | null;
  sla: SafetySlaConfig;
  assignees: AdminAssignee[];
  canAck: boolean;
  canResolve: boolean;
  canTriage: boolean;
}

function slaStyle(tier: SlaTier): CSSProperties {
  if (tier === 'critical') {
    return {
      background: 'var(--color-semantic-danger-tint)',
      borderColor: 'var(--color-semantic-danger-fill)',
      color: 'var(--color-semantic-danger)',
    };
  }
  if (tier === 'warning') {
    return {
      background: 'var(--color-semantic-warning-tint)',
      borderColor: 'var(--color-semantic-warning-fill)',
      color: 'var(--color-semantic-warning)',
    };
  }
  return {};
}

export function SafetyBoard({
  citySlug,
  cityId,
  initialSosRows,
  initialIncidentRows,
  initialSelectedSosId,
  sla,
  assignees,
  canAck,
  canResolve,
  canTriage,
}: SafetyBoardProps) {
  const [sosRows, setSosRows] = useState(initialSosRows);
  const [incidentRows, setIncidentRows] = useState(initialIncidentRows);
  const [selectedSosId, setSelectedSosId] = useState<string | null>(initialSelectedSosId);
  const [resolveNote, setResolveNote] = useState('');
  const [triageStatus, setTriageStatus] = useState('triaged');
  const [triageSeverity, setTriageSeverity] = useState(2);
  const [triageAssignee, setTriageAssignee] = useState('');
  const [selectedIncidentId, setSelectedIncidentId] = useState<string | null>(
    initialIncidentRows[0]?.id ?? null
  );
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [nowMs, setNowMs] = useState(() => Date.now());
  const [pending, startTransition] = useTransition();

  useEffect(() => {
    setSosRows(initialSosRows);
    setIncidentRows(initialIncidentRows);
  }, [initialIncidentRows, initialSosRows]);

  useEffect(() => {
    const timer = window.setInterval(() => setNowMs(Date.now()), 1000);
    return () => window.clearInterval(timer);
  }, []);

  useEffect(() => {
    const supabase = createClient();
    const channel = supabase
      .channel(`safety-board-${cityId}`)
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'sos_alerts' },
        () => {
          window.location.reload();
        }
      )
      .subscribe();

    return () => {
      void supabase.removeChannel(channel);
    };
  }, [cityId]);

  const selectedSos = useMemo(
    () => sosRows.find((row) => row.id === selectedSosId) ?? null,
    [sosRows, selectedSosId]
  );

  const selectedIncident = useMemo(
    () => incidentRows.find((row) => row.id === selectedIncidentId) ?? null,
    [incidentRows, selectedIncidentId]
  );

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

  function ageSeconds(createdAt: string): number {
    return Math.max(0, (nowMs - new Date(createdAt).getTime()) / 1000);
  }

  return (
    <div data-testid="safety-board">
      <p style={{ marginBottom: 'var(--space-4)', fontSize: '0.875rem' }}>
        SLA targets from config: acknowledge within{' '}
        <strong>{sla.ackSlaS}s</strong>, escalate visually at{' '}
        <strong>{sla.escalateSlaS}s</strong>.{' '}
        <Link href={RUNBOOK_PATH} data-testid="safety-runbook-link">
          SOS escalation runbook
        </Link>
      </p>

      {error ? (
        <div className="error-banner" role="alert" data-testid="safety-error">
          {error}
        </div>
      ) : null}
      {message ? (
        <div
          className="card"
          role="status"
          data-testid="safety-success"
          style={{ marginBottom: 'var(--space-4)', fontSize: '0.875rem' }}
        >
          {message}
        </div>
      ) : null}

      <section style={{ marginBottom: 'var(--space-8)' }}>
        <h2 style={{ margin: '0 0 var(--space-3)', fontSize: '1.125rem' }}>Open SOS</h2>
        {sosRows.length === 0 ? (
          <p style={{ color: 'var(--color-text-muted)' }} data-testid="safety-sos-empty">
            No open SOS alerts for this city.
          </p>
        ) : (
          <table className="data-table" data-testid="safety-sos-table">
            <thead>
              <tr>
                <th>Age</th>
                <th>SLA</th>
                <th>Raiser</th>
                <th>Trip</th>
                <th>Location</th>
                <th>Status</th>
                <th>Action</th>
              </tr>
            </thead>
            <tbody>
              {sosRows.map((row) => {
                const ageS = ageSeconds(row.created_at);
                const tier =
                  row.status === 'open' ? slaTierForOpenSos(ageS, sla) : ('normal' as SlaTier);
                return (
                  <tr
                    key={row.id}
                    data-testid={`safety-sos-row-${row.id}`}
                    onClick={() => setSelectedSosId(row.id)}
                    style={{
                      cursor: 'pointer',
                      background: row.id === selectedSosId ? 'var(--color-bg)' : undefined,
                    }}
                  >
                    <td data-testid={`safety-sos-age-${row.id}`}>{formatAgeSeconds(ageS)}</td>
                    <td>
                      <span
                        className="badge"
                        data-testid={`safety-sos-sla-${row.id}`}
                        style={slaStyle(tier)}
                      >
                        {row.status === 'open' ? slaTierLabel(tier) : row.status}
                      </span>
                    </td>
                    <td>
                      {row.raiser_name ?? row.raised_by.slice(0, 8)} ({row.raised_role})
                    </td>
                    <td>{row.trip_id?.slice(0, 8) ?? '—'}</td>
                    <td>{formatCoordinates(row.lat, row.lng)}</td>
                    <td>
                      <span className={`badge badge-${row.status}`}>{row.status}</span>
                    </td>
                    <td>
                      {canAck && row.status === 'open' ? (
                        <button
                          type="button"
                          className="btn btn-primary"
                          data-testid={`safety-ack-${row.id}`}
                          disabled={pending}
                          onClick={(event) => {
                            event.stopPropagation();
                            runAction(() => acknowledgeSos(citySlug, row.id));
                          }}
                        >
                          Acknowledge
                        </button>
                      ) : (
                        '—'
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </section>

      {selectedSos ? (
        <section
          className="card"
          style={{ marginBottom: 'var(--space-8)' }}
          data-testid="safety-sos-detail"
        >
          <h2 style={{ margin: '0 0 var(--space-3)', fontSize: '1.125rem' }}>Trip context</h2>
          <dl style={{ margin: 0, display: 'grid', gap: 'var(--space-2)', fontSize: '0.875rem' }}>
            <div>
              <dt style={{ fontWeight: 600 }}>Rider</dt>
              <dd style={{ margin: 0 }}>{selectedSos.rider_name ?? '—'}</dd>
            </div>
            <div>
              <dt style={{ fontWeight: 600 }}>Driver</dt>
              <dd style={{ margin: 0 }}>{selectedSos.driver_name ?? '—'}</dd>
            </div>
            <div>
              <dt style={{ fontWeight: 600 }}>Vehicle</dt>
              <dd style={{ margin: 0 }}>{selectedSos.vehicle_plate ?? '—'}</dd>
            </div>
            <div>
              <dt style={{ fontWeight: 600 }}>Trip status</dt>
              <dd style={{ margin: 0 }}>{selectedSos.trip_status ?? '—'}</dd>
            </div>
            <div>
              <dt style={{ fontWeight: 600 }}>Destination</dt>
              <dd style={{ margin: 0 }}>{selectedSos.destination_label ?? '—'}</dd>
            </div>
            {selectedSos.share_issued ? (
              <div>
                <dt style={{ fontWeight: 600 }}>Live trip link</dt>
                <dd style={{ margin: 0 }} data-testid="safety-sos-share-issued">
                  Issued with this alert. The link was sent to the rider&apos;s emergency
                  contacts. The token is not stored on this desk.
                </dd>
              </div>
            ) : null}
            <div>
              <dt style={{ fontWeight: 600 }}>Live location</dt>
              <dd style={{ margin: 0 }}>
                {formatCoordinates(selectedSos.lat, selectedSos.lng)}
                {selectedSos.lat != null && selectedSos.lng != null ? (
                  <>
                    {' '}
                    <a
                      href={mapExternalUrl(selectedSos.lat, selectedSos.lng)}
                      target="_blank"
                      rel="noreferrer"
                    >
                      Open map
                    </a>
                  </>
                ) : null}
              </dd>
            </div>
          </dl>

          {canResolve && selectedSos.status !== 'resolved' && selectedSos.status !== 'false_alarm' ? (
            <div style={{ marginTop: 'var(--space-4)' }}>
              <label htmlFor="resolve-note" style={{ display: 'block', fontSize: '0.875rem' }}>
                Resolution note
              </label>
              <input
                id="resolve-note"
                value={resolveNote}
                onChange={(event) => setResolveNote(event.target.value)}
                style={{ width: '100%', marginTop: 'var(--space-2)' }}
              />
              <div style={{ display: 'flex', gap: 'var(--space-2)', marginTop: 'var(--space-3)' }}>
                <button
                  type="button"
                  className="btn btn-primary"
                  data-testid="safety-resolve"
                  disabled={pending}
                  onClick={() =>
                    runAction(() => resolveSos(citySlug, selectedSos.id, 'resolved', resolveNote))
                  }
                >
                  Resolve
                </button>
                <button
                  type="button"
                  className="btn"
                  data-testid="safety-false-alarm"
                  disabled={pending}
                  onClick={() =>
                    runAction(() =>
                      resolveSos(citySlug, selectedSos.id, 'false_alarm', resolveNote)
                    )
                  }
                >
                  False alarm
                </button>
              </div>
            </div>
          ) : null}
        </section>
      ) : null}

      <section>
        <h2 style={{ margin: '0 0 var(--space-3)', fontSize: '1.125rem' }}>Incident queue</h2>
        {incidentRows.length === 0 ? (
          <p style={{ color: 'var(--color-text-muted)' }} data-testid="safety-incidents-empty">
            No open incidents for this city.
          </p>
        ) : (
          <>
            <table className="data-table" data-testid="safety-incidents-table">
              <thead>
                <tr>
                  <th>Type</th>
                  <th>Severity</th>
                  <th>Reporter</th>
                  <th>Status</th>
                  <th>Reported</th>
                </tr>
              </thead>
              <tbody>
                {incidentRows.map((row) => (
                  <tr
                    key={row.id}
                    data-testid={`safety-incident-row-${row.id}`}
                    onClick={() => setSelectedIncidentId(row.id)}
                    style={{
                      cursor: 'pointer',
                      background: row.id === selectedIncidentId ? 'var(--color-bg)' : undefined,
                    }}
                  >
                    <td>{incidentTypeLabel(row.type)}</td>
                    <td>S{row.severity}</td>
                    <td>{row.reporter_name ?? row.reported_by.slice(0, 8)}</td>
                    <td>
                      <span className={`badge badge-${row.status}`}>{row.status}</span>
                    </td>
                    <td>{new Date(row.reported_at).toLocaleString()}</td>
                  </tr>
                ))}
              </tbody>
            </table>

            {selectedIncident && canTriage ? (
              <div
                className="card"
                style={{ marginTop: 'var(--space-4)' }}
                data-testid="safety-incident-triage"
              >
                <h3 style={{ margin: '0 0 var(--space-3)', fontSize: '1rem' }}>Triage</h3>
                <p style={{ margin: '0 0 var(--space-3)', fontSize: '0.875rem' }}>
                  {selectedIncident.description ?? 'No description.'}
                </p>
                <div className="field">
                  <label htmlFor="triage-status">Status</label>
                  <select
                    id="triage-status"
                    value={triageStatus}
                    onChange={(event) => setTriageStatus(event.target.value)}
                  >
                    <option value="open">open</option>
                    <option value="triaged">triaged</option>
                    <option value="resolved">resolved</option>
                    <option value="dismissed">dismissed</option>
                  </select>
                </div>
                <div className="field">
                  <label htmlFor="triage-severity">Severity (1–4)</label>
                  <input
                    id="triage-severity"
                    type="number"
                    min={1}
                    max={4}
                    value={triageSeverity}
                    onChange={(event) => setTriageSeverity(Number(event.target.value))}
                  />
                </div>
                <div className="field">
                  <label htmlFor="triage-assignee">Assign to</label>
                  <select
                    id="triage-assignee"
                    value={triageAssignee}
                    onChange={(event) => setTriageAssignee(event.target.value)}
                  >
                    <option value="">Unchanged</option>
                    {assignees.map((admin) => (
                      <option key={admin.id} value={admin.id}>
                        {admin.display_name ?? admin.id.slice(0, 8)} ({admin.role})
                      </option>
                    ))}
                  </select>
                </div>
                <button
                  type="button"
                  className="btn btn-primary"
                  data-testid="safety-triage-submit"
                  disabled={pending}
                  onClick={() =>
                    runAction(() =>
                      triageIncident(
                        citySlug,
                        selectedIncident.id,
                        triageStatus,
                        triageAssignee || null,
                        triageSeverity
                      )
                    )
                  }
                >
                  Update incident
                </button>
              </div>
            ) : null}
          </>
        )}
      </section>
    </div>
  );
}

export { parseGeoPoint };
