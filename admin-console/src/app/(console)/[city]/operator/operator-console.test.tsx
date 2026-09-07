import React from 'react';
import { describe, expect, it } from 'vitest';
import { renderToStaticMarkup } from 'react-dom/server';
import type { OperatorOverview } from '@/lib/operator/types';
import { OperatorConsole } from '@/app/(console)/[city]/operator/operator-console';
import {
  getAllowedRolesForSegment,
  ROUTE_ALLOWLIST,
} from '@/lib/authz/routes.js';

const overview: OperatorOverview = {
  operator_account_id: 'op-1',
  from: '2026-01-01T00:00:00Z',
  to: '2026-01-08T00:00:00Z',
  driver_count: 12,
  trips_completed: 84,
  fare_discrepancy_rate: 0.04,
  aggregate_only: true,
  online_total: 5,
  online_at_park: 3,
  online_roaming: 2,
  trips_per_day: 12,
};

describe('authz routes — Phase 8 portals', () => {
  it('gates corporate portal to corporate_admin, superadmin, finance', () => {
    expect(getAllowedRolesForSegment('corporate')).toEqual([
      'superadmin',
      'finance',
      'corporate_admin',
    ]);
  });

  it('gates operator portal to operator_viewer, superadmin, ops_lead', () => {
    expect(getAllowedRolesForSegment('operator')).toEqual([
      'superadmin',
      'ops_lead',
      'operator_viewer',
    ]);
  });

  it('gates revenue hooks to superadmin and finance', () => {
    expect(getAllowedRolesForSegment('revenue')).toEqual(['superadmin', 'finance']);
    expect(ROUTE_ALLOWLIST.revenue).not.toContain('corporate_admin');
  });
});

describe('OperatorConsole (O-01)', () => {
  it('renders aggregate KPI tiles without rider identity fields', () => {
    const html = renderToStaticMarkup(
      <OperatorConsole initialOverview={overview} isOperatorViewer />
    );
    expect(html).toContain('data-testid="operator-console"');
    expect(html).toContain('data-testid="operator-online-total"');
    expect(html).toContain('data-testid="operator-fare-discrepancy"');
    expect(html).not.toContain('rider_id');
    expect(html).not.toContain('rider-id');
    expect(html).toContain('data-testid="operator-privacy-guard"');
    expect(html).toContain('PASS');
  });

  it('shows unscoped message when not operator_viewer', () => {
    const html = renderToStaticMarkup(
      <OperatorConsole initialOverview={null} isOperatorViewer={false} />
    );
    expect(html).toContain('data-testid="operator-console-unscoped"');
  });
});
