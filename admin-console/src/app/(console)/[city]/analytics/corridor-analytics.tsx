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

      <div className="filter-bar">
        <div className="field" style={{ marginBottom: 0, minWidth: 280 }}>
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
        <span className="note" style={{ margin: 0, alignSelf: 'center' }}>
          Last 24 hours
        </span>
      </div>

      <p className="note" data-testid="conversion-diagnostic-note" style={{ margin: '0 0 var(--space-4)' }}>
        {CONVERSION_DIAGNOSTIC_NOTE}
      </p>

      {summary ? (
        <div className="kpi-grid" style={{ marginBottom: 'var(--space-3)' }}>
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
            <div key={tile.id} className="kpi" data-testid={tile.id}>
              <div className="kpi-label">{tile.label}</div>
              <div className="kpi-value">{tile.value}</div>
            </div>
          ))}
        </div>
      ) : null}

      <div style={{ display: 'flex', gap: 'var(--space-3)', marginBottom: 'var(--space-4)' }}>
        <button type="button" className="btn btn-secondary" onClick={() => exportCsv()} disabled={!data}>
          Export CSV
        </button>
        <Link href={`/${citySlug}/dashboard`} className="btn btn-ghost">
          Back to dashboard
        </Link>
      </div>

      <h2 className="section-title">Time series</h2>
      <table className="data-table" data-testid="analytics-series-table">
        <thead>
          <tr>
            <th>Bucket</th>
            <th className="num">Searches</th>
            <th className="num">Ambient views</th>
            <th className="num">Commits</th>
            <th className="num">Conversion</th>
            <th className="num">Requests</th>
            <th className="num">Completed</th>
          </tr>
        </thead>
        <tbody>
          {(data?.series ?? []).map((row) => (
            <tr key={row.bucket_start}>
              <td>{new Date(row.bucket_start).toLocaleString()}</td>
              <td className="num">{row.searches}</td>
              <td className="num">{row.ambient_views}</td>
              <td className="num">{row.commits}</td>
              <td className="num">{formatRate(row.ambient_to_commit_rate)}</td>
              <td className="num">{row.requests}</td>
              <td className="num">{row.completed_trips}</td>
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

      <h2 className="section-title section-gap">Coverage gaps</h2>
      <table className="data-table" data-testid="analytics-gaps-table">
        <thead>
          <tr>
            <th>Searched at</th>
            <th>Nearest stage</th>
            <th className="num">Distance (m)</th>
            <th className="num">Ambient vehicles</th>
            <th>Location</th>
          </tr>
        </thead>
        <tbody>
          {(data?.coverage_gaps ?? []).map((gap) => (
            <tr key={gap.id}>
              <td>{new Date(gap.searched_at).toLocaleString()}</td>
              <td>{gap.nearest_stage_name ?? '—'}</td>
              <td className="num">{gap.nearest_stage_distance_m ?? '—'}</td>
              <td className="num">{gap.ambient_vehicle_count}</td>
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
