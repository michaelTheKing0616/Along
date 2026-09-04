'use client';

import { useMemo, useState, useTransition } from 'react';
import { diffParksCsv, parseParksCsv, type ParkImportDiffRow } from '@/lib/deploy/csv-parks';
import { advanceCityStatus, applyParksImport } from './actions';

interface DeployPlaybookProps {
  citySlug: string;
  cityId: string;
  cityStatus: string;
  stats: {
    parkCount: number;
    routeCount: number;
    corridorCount: number;
    parkNames: string[];
  };
}

const CHECKLIST = [
  { id: 'geofence', label: 'Geofence polygon defined (draw/upload)', manual: true },
  { id: 'parks_csv', label: 'Backbone parks CSV reviewed', manual: false },
  { id: 'routes', label: 'Routes seeded for corridors', manual: false },
  { id: 'fares', label: 'Leg/through fares present', manual: true },
  { id: 'config', label: 'City config overrides reviewed', manual: true },
  { id: 'tiles', label: 'Vector tile coverage check', manual: true },
  { id: 'osrm', label: 'OSRM extract check', manual: true },
] as const;

export function DeployPlaybook({ citySlug, cityId, cityStatus, stats }: DeployPlaybookProps) {
  const [csvText, setCsvText] = useState('');
  const [diff, setDiff] = useState<ParkImportDiffRow[] | null>(null);
  const [parseErrors, setParseErrors] = useState<string[]>([]);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [checked, setChecked] = useState<Record<string, boolean>>({});
  const [pending, startTransition] = useTransition();

  const autoChecks = useMemo(
    () => ({
      parks_csv: stats.parkCount > 0 || (diff?.some((d) => d.action === 'create') ?? false),
      routes: stats.routeCount > 0,
    }),
    [stats, diff]
  );

  function runDryRun() {
    setMessage(null);
    setError(null);
    const parsed = parseParksCsv(csvText);
    if (!parsed.ok) {
      setParseErrors(parsed.errors);
      setDiff(null);
      return;
    }
    setParseErrors([]);
    setDiff(diffParksCsv(parsed.rows, stats.parkNames));
  }

  function runApply() {
    if (!diff) return;
    setMessage(null);
    setError(null);
    startTransition(async () => {
      const result = await applyParksImport(citySlug, cityId, diff);
      if (result.ok) {
        setMessage(`Applied import: ${result.created} created, ${result.skipped} skipped.`);
        setDiff(null);
        setCsvText('');
      } else {
        setError(result.error);
      }
    });
  }

  return (
    <div data-testid="deploy-playbook">
      {error ? <div className="error-banner" role="alert">{error}</div> : null}
      {message ? (
        <div className="card" role="status" data-testid="deploy-success" style={{ marginBottom: 'var(--space-4)', fontSize: '0.875rem' }}>
          {message}
        </div>
      ) : null}

      <section className="card" style={{ marginBottom: 'var(--space-6)' }}>
        <h2 style={{ margin: '0 0 var(--space-4)', fontSize: '1rem' }}>Deployment checklist</h2>
        <ul style={{ listStyle: 'none', padding: 0, margin: 0 }}>
          {CHECKLIST.map((item) => {
            const done = item.manual ? checked[item.id] : autoChecks[item.id as keyof typeof autoChecks];
            return (
              <li key={item.id} style={{ marginBottom: 'var(--space-2)', fontSize: '0.875rem' }}>
                <label style={{ display: 'flex', gap: 'var(--space-2)', alignItems: 'center' }}>
                  <input
                    type="checkbox"
                    checked={Boolean(done)}
                    disabled={!item.manual}
                    onChange={(e) =>
                      setChecked((prev) => ({ ...prev, [item.id]: e.target.checked }))
                    }
                    data-testid={`checklist-${item.id}`}
                  />
                  {item.label}
                  {!item.manual ? (
                    <span style={{ color: 'var(--color-text-muted)' }}>(auto)</span>
                  ) : null}
                </label>
              </li>
            );
          })}
        </ul>
        <p style={{ margin: 'var(--space-4) 0 0', fontSize: '0.8125rem', color: 'var(--color-text-muted)' }}>
          Corridors: {stats.corridorCount} · Parks: {stats.parkCount} · Routes: {stats.routeCount}
        </p>
      </section>

      <section className="card" style={{ marginBottom: 'var(--space-6)' }}>
        <h2 style={{ margin: '0 0 var(--space-2)', fontSize: '1rem' }}>Backbone parks CSV</h2>
        <p style={{ margin: '0 0 var(--space-4)', fontSize: '0.875rem', color: 'var(--color-text-muted)' }}>
          Format: <code>name,lat,lng[,aliases pipe-separated]</code>. Dry-run shows create/skip diff
          before apply (rows use <code>import</code> source, <code>candidate</code> status).
        </p>
        <textarea
          value={csvText}
          onChange={(e) => setCsvText(e.target.value)}
          rows={6}
          style={{
            width: '100%',
            fontFamily: 'var(--font-mono)',
            fontSize: '0.8125rem',
            padding: 'var(--space-3)',
            border: '1px solid var(--color-border)',
            borderRadius: 'var(--radius-sm)',
          }}
          placeholder={'name,lat,lng,aliases\nE2E Test Park,9.060,7.410,E2E|Test'}
          data-testid="deploy-csv-input"
        />
        {parseErrors.length > 0 ? (
          <ul className="error-banner" style={{ marginTop: 'var(--space-3)' }}>
            {parseErrors.map((e) => (
              <li key={e}>{e}</li>
            ))}
          </ul>
        ) : null}
        <div style={{ display: 'flex', gap: 'var(--space-2)', marginTop: 'var(--space-4)' }}>
          <button type="button" className="btn" onClick={runDryRun} data-testid="deploy-dry-run">
            Dry-run diff
          </button>
          <button
            type="button"
            className="btn btn-primary"
            disabled={!diff || pending || !diff.some((d) => d.action === 'create')}
            onClick={runApply}
            data-testid="deploy-apply"
          >
            Initialize (apply import)
          </button>
        </div>

        {diff ? (
          <table className="data-table" style={{ marginTop: 'var(--space-4)' }} data-testid="deploy-diff-table">
            <thead>
              <tr>
                <th>Name</th>
                <th>Lat</th>
                <th>Lng</th>
                <th>Action</th>
                <th>Reason</th>
              </tr>
            </thead>
            <tbody>
              {diff.map((row) => (
                <tr key={row.name} data-testid={`deploy-diff-${row.action}-${row.name}`}>
                  <td>{row.name}</td>
                  <td>{row.lat}</td>
                  <td>{row.lng}</td>
                  <td>{row.action}</td>
                  <td>{row.reason ?? '—'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        ) : null}
      </section>

      <section className="card">
        <h2 style={{ margin: '0 0 var(--space-4)', fontSize: '1rem' }}>City status</h2>
        <p style={{ margin: '0 0 var(--space-4)', fontSize: '0.875rem' }}>
          Current: <strong>{cityStatus}</strong>
        </p>
        {cityStatus === 'pre_seed' ? (
          <button
            type="button"
            className="btn btn-primary"
            disabled={pending}
            data-testid="advance-city-alpha"
            onClick={() =>
              startTransition(async () => {
                const result = await advanceCityStatus(citySlug, cityId, 'alpha');
                if (result.ok) setMessage('City advanced to alpha.');
                else setError(result.error);
              })
            }
          >
            Advance to alpha
          </button>
        ) : null}
      </section>
    </div>
  );
}
