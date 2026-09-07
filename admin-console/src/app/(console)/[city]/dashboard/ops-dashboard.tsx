'use client';

import React from 'react';
import Link from 'next/link';
import {
  CONVERSION_DIAGNOSTIC_NOTE,
  formatCount,
  formatRate,
  formatSeconds,
} from '@/lib/analytics/format';
import type { OpsDashboardCounts, OpsDashboardKpis } from '@/lib/analytics/types';

interface OpsDashboardProps {
  citySlug: string;
  windowLabel: string;
  kpis: OpsDashboardKpis;
  counts: OpsDashboardCounts;
}

type Tile = {
  testId: string;
  label: string;
  value: string;
  href?: string;
  hint?: string;
};

export function OpsDashboard({ citySlug, windowLabel, kpis, counts }: OpsDashboardProps) {
  const tiles: Tile[] = [
    { testId: 'kpi-searches', label: 'Searches', value: formatCount(kpis.searches), href: `/${citySlug}/analytics` },
    {
      testId: 'kpi-conversion',
      label: 'Ambient→commit',
      value: formatRate(kpis.ambient_to_commit_rate),
      href: `/${citySlug}/analytics`,
      hint: 'Diagnostic only',
    },
    { testId: 'kpi-requests', label: 'Requests', value: formatCount(kpis.requests), href: `/${citySlug}/integrity` },
    { testId: 'kpi-accept-rate', label: 'Accept rate', value: formatRate(kpis.accept_rate) },
    { testId: 'kpi-completed', label: 'Completed trips', value: formatCount(kpis.completed_trips) },
    { testId: 'kpi-wait', label: 'Median wait', value: formatSeconds(kpis.median_wait_s) },
    {
      testId: 'kpi-fare-discrepancy',
      label: 'Fare discrepancy',
      value: formatRate(kpis.fare_discrepancy_rate),
      href: `/${citySlug}/corrections`,
    },
    { testId: 'kpi-open-sos', label: 'Open SOS', value: formatCount(counts.openSos), href: `/${citySlug}/safety` },
    { testId: 'kpi-open-flags', label: 'Open flags', value: formatCount(counts.openFlags), href: `/${citySlug}/integrity` },
    {
      testId: 'kpi-verification-queue',
      label: 'Verification queue',
      value: formatCount(counts.verificationQueue),
      href: `/${citySlug}/verification`,
    },
    {
      testId: 'kpi-drivers-online',
      label: 'Drivers online',
      value: formatCount(counts.driversOnline),
      hint: `${counts.driversAtPark} at park · ${counts.driversRoaming} roaming`,
    },
  ];

  return (
    <div data-testid="ops-dashboard">
      <p style={{ color: 'var(--color-text-muted)', marginBottom: 'var(--space-4)' }}>
        City KPIs for the last {windowLabel} across {kpis.corridors} corridor
        {kpis.corridors === 1 ? '' : 's'}.
      </p>
      <p
        className="card"
        data-testid="conversion-diagnostic-note"
        style={{ marginBottom: 'var(--space-4)', fontSize: '0.875rem' }}
      >
        {CONVERSION_DIAGNOSTIC_NOTE}
      </p>
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fill, minmax(11rem, 1fr))',
          gap: 'var(--space-4)',
        }}
      >
        {tiles.map((tile) => {
          const body = (
            <div className="card" data-testid={tile.testId} style={{ height: '100%' }}>
              <div style={{ fontSize: '0.8125rem', color: 'var(--color-text-muted)' }}>{tile.label}</div>
              <div style={{ fontSize: '1.5rem', fontWeight: 600, marginTop: 'var(--space-1)' }}>{tile.value}</div>
              {tile.hint ? (
                <div style={{ fontSize: '0.75rem', color: 'var(--color-text-muted)', marginTop: 'var(--space-1)' }}>
                  {tile.hint}
                </div>
              ) : null}
            </div>
          );

          if (tile.href) {
            return (
              <Link key={tile.testId} href={tile.href} style={{ textDecoration: 'none', color: 'inherit' }}>
                {body}
              </Link>
            );
          }
          return <div key={tile.testId}>{body}</div>;
        })}
      </div>
    </div>
  );
}
