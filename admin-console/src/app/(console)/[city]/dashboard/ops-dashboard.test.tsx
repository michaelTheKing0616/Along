import React from 'react';
import { describe, expect, it } from 'vitest';
import { renderToStaticMarkup } from 'react-dom/server';
import { OpsDashboard } from './ops-dashboard';
import type { OpsDashboardCounts, OpsDashboardKpis } from '@/lib/analytics/types';

const kpis: OpsDashboardKpis = {
  searches: 120,
  ambient_views: 96,
  commits: 24,
  ambient_to_commit_rate: 0.25,
  ambient_to_commit_diagnostic: true,
  requests: 40,
  accept_rate: 0.75,
  completed_trips: 30,
  fulfilment_rate: 0.8,
  median_wait_s: 180,
  fare_discrepancy_rate: 0.05,
  avg_candidates_per_search: 2.4,
  avg_direct_candidates: 1.1,
  coverage_gap_count: 3,
  corridors: 2,
};

const counts: OpsDashboardCounts = {
  openSos: 1,
  openFlags: 4,
  verificationQueue: 6,
  driversOnline: 12,
  driversAtPark: 8,
  driversRoaming: 4,
};

describe('OpsDashboard', () => {
  it('renders paginated analytics KPI tiles including conversion metric', () => {
    const html = renderToStaticMarkup(
      <OpsDashboard citySlug="abuja" windowLabel="24 h" kpis={kpis} counts={counts} />
    );
    expect(html).toContain('data-testid="ops-dashboard"');
    expect(html).toContain('data-testid="kpi-conversion"');
    expect(html).toContain('25.0%');
    expect(html).toContain('data-testid="kpi-searches"');
  });

  it('shows conversion as diagnostic-only with no action controls (FM13)', () => {
    const html = renderToStaticMarkup(
      <OpsDashboard citySlug="abuja" windowLabel="24 h" kpis={kpis} counts={counts} />
    );
    expect(html).toContain('data-testid="conversion-diagnostic-note"');
    expect(html).toMatch(/does not trigger/i);
    expect(html).not.toMatch(/admin_review_flag|standing|block/i);
  });
});
