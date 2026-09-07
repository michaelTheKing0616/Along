'use client';

import Link from 'next/link';
import { useMemo, useState, useTransition } from 'react';
import {
  CONVERSION_DIAGNOSTIC_NOTE,
  formatCount,
  formatRate,
  formatSeconds,
} from '@/lib/analytics/format';
import type {
  CorridorAnalyticsResponse,
  CorridorOption,
  CoverageGapRow,
} from '@/lib/analytics/types';

interface CorridorAnalyticsProps {
  citySlug: string;
  corridors: CorridorOption[];
  initialCorridorId: string | null;
  initialData: CorridorAnalyticsResponse | null;
  loadPage: (
    corridorId: string,
    cursor: string | null
  ) => Promise<{ ok: boolean; data?: CorridorAnalyticsResponse; error?: string }>;
}

function seriesToCsv(rows: CorridorAnalyticsResponse['series']): string {
  const header = 'bucket_start,searches,ambient_views,commits,ambient_to_commit_rate,requests,completed_trips';
  const lines = rows.map((row) =>
    [
      row.bucket_start,
      row.searches,
      row.ambient_views,
      row.commits,
      row.ambient_to_commit_rate ?? '',
      row.requests,
      row.completed_trips,
    ].join(',')
  );
  return [header, ...lines].join('\n');
}

function gapsToCsv(rows: CoverageGapRow[]): string {
  const header = 'searched_at,nearest_stage,distance_m,ambient_vehicle_count,lat,lng';
  const lines = rows.map((row) =>
    [
      row.searched_at,
      row.nearest_stage_name ?? '',
      row.nearest_stage_distance_m ?? '',
      row.ambient_vehicle_count,
      row.location.lat,
      row.location.lng,
    ].join(',')
  );
  return [header, ...lines].join('\n');
}

export function CorridorAnalytics({
  citySlug,
  corridors,
  initialCorridorId,
  initialData,
  loadPage,
}: CorridorAnalyticsProps) {
  const [corridorId, setCorridorId] = useState(initialCorridorId ?? corridors[0]?.id ?? '');
  const [data, setData] = useState<CorridorAnalyticsResponse | null>(initialData);
  const [error, setError] = useState<string | null>(null);
  const [pending, startTransition] = useTransition();

  const summary = data?.summary ?? null;

  const selectedCorridor = useMemo(
    () => corridors.find((c) => c.id === corridorId) ?? null,
    [corridors, corridorId]
  );

  function refresh(cursor: string | null) {
    if (!corridorId) return;
    setError(null);
    startTransition(async () => {
      const result = await loadPage(corridorId, cursor);
      if (!result.ok || !result.data) {
        setError(result.error ?? 'Failed to load analytics.');
        return;
      }
      setData((prev) =>
        cursor && prev
          ? {
              ...result.data!,
              series: [...prev.series, ...result.data!.series],
              coverage_gaps: result.data!.coverage_gaps,
            }
          : result.data!
      );
    });
  }

  function exportCsv() {
    if (!data) return;
    const blob = new Blob([`${seriesToCsv(data.series)}\n\n${gapsToCsv(data.coverage_gaps)}`], {
      type: 'text/csv;charset=utf-8',
    });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `along-analytics-${selectedCorridor?.slug ?? 'corridor'}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  }

  return (
    <div data-testid="corridor-analytics">
      {error ? (
        <div className="error-banner" role="alert" data-testid="analytics-error">
          {error}
        </div>
      ) : null}

      <div className="card" style={{ marginBottom: 'var(--space-4)' }}>
        <div className="field">
          <label htmlFor="corridor-select">Corridor</label>
          <select
            id="corridor-select"
            value={corridorId}
            onChange={(e) => {
              setCorridorId(e.target.value);
              startTransition(async () => {
                const result = await loadPage(e.target.value, null);
                if (result.ok && result.data) setData(result.data);
              });
            }}
          >
            {corridors.map((c) => (
              <option key={c.id} value={c.id}>
                {c.name}
              </option>
            ))}
          </select>
        </div>
        <p style={{ fontSize: '0.875rem', color: 'var(--color-text-muted)', marginTop: 'var(--space-2)' }}>
          Window: last 24 h · page size from <code>analytics.page_size</code>
        </p>
      </div>

      <p
        className="card"
        data-testid="conversion-diagnostic-note"
        style={{ marginBottom: 'var(--space-4)', fontSize: '0.875rem' }}
      >
        {CONVERSION_DIAGNOSTIC_NOTE}
      </p>

      {summary ? (
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fill, minmax(10rem, 1fr))',
            gap: 'var(--space-3)',
            marginBottom: 'var(--space-4)',
          }}
        >
          {[
            { id: 'analytics-searches', label: 'Searches', value: formatCount(summary.searches) },
            {
              id: 'analytics-conversion',
              label: 'Ambient→commit',
              value: formatRate(summary.ambient_to_commit_rate),
            },
            { id: 'analytics-requests', label: 'Requests', value: formatCount(summary.requests) },
            { id: 'analytics-fulfilment', label: 'Fulfilment', value: formatRate(summary.fulfilment_rate) },
            { id: 'analytics-wait', label: 'Median wait', value: formatSeconds(summary.median_wait_s) },
            {
              id: 'analytics-fare-discrepancy',
              label: 'Fare discrepancy',
              value: formatRate(summary.fare_discrepancy_rate),
            },
            {
              id: 'analytics-candidates',
              label: 'Candidates / search',
              value: summary.avg_candidates_per_search.toFixed(1),
            },
            {
              id: 'analytics-direct',
              label: 'Direct / search',
              value: summary.avg_direct_candidates.toFixed(1),
            },
          ].map((tile) => (
            <div key={tile.id} className="card" data-testid={tile.id}>
              <div style={{ fontSize: '0.8125rem', color: 'var(--color-text-muted)' }}>{tile.label}</div>
              <div style={{ fontSize: '1.25rem', fontWeight: 600 }}>{tile.value}</div>
            </div>
          ))}
        </div>
      ) : null}

      <div style={{ display: 'flex', gap: 'var(--space-3)', marginBottom: 'var(--space-4)' }}>
        <button type="button" className="btn btn-primary" onClick={() => exportCsv()} disabled={!data}>
          Export CSV
        </button>
        <Link href={`/${citySlug}/dashboard`} className="btn">
          Back to dashboard
        </Link>
      </div>

      <h2 style={{ fontSize: '1rem' }}>Time series</h2>
      <table className="data-table" data-testid="analytics-series-table">
        <thead>
          <tr>
            <th>Bucket</th>
            <th>Searches</th>
            <th>Ambient views</th>
            <th>Commits</th>
            <th>Conversion</th>
            <th>Requests</th>
            <th>Completed</th>
          </tr>
        </thead>
        <tbody>
          {(data?.series ?? []).map((row) => (
            <tr key={row.bucket_start}>
              <td>{new Date(row.bucket_start).toLocaleString()}</td>
              <td>{row.searches}</td>
              <td>{row.ambient_views}</td>
              <td>{row.commits}</td>
              <td>{formatRate(row.ambient_to_commit_rate)}</td>
              <td>{row.requests}</td>
              <td>{row.completed_trips}</td>
            </tr>
          ))}
        </tbody>
      </table>

      {data?.meta.next_cursor ? (
        <button
          type="button"
          className="btn"
          style={{ marginTop: 'var(--space-3)' }}
          disabled={pending}
          data-testid="analytics-load-more"
          onClick={() => refresh(data.meta.next_cursor)}
        >
          {pending ? 'Loading…' : 'Load more buckets'}
        </button>
      ) : null}

      <h2 style={{ fontSize: '1rem', marginTop: 'var(--space-6)' }}>Coverage gaps</h2>
      <table className="data-table" data-testid="analytics-gaps-table">
        <thead>
          <tr>
            <th>Searched at</th>
            <th>Nearest stage</th>
            <th>Distance (m)</th>
            <th>Ambient vehicles</th>
            <th>Location</th>
          </tr>
        </thead>
        <tbody>
          {(data?.coverage_gaps ?? []).map((gap) => (
            <tr key={gap.id}>
              <td>{new Date(gap.searched_at).toLocaleString()}</td>
              <td>{gap.nearest_stage_name ?? '—'}</td>
              <td>{gap.nearest_stage_distance_m ?? '—'}</td>
              <td>{gap.ambient_vehicle_count}</td>
              <td>
                {gap.location.lat.toFixed(4)}, {gap.location.lng.toFixed(4)}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
