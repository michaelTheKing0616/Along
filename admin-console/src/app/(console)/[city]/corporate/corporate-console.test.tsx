import React from 'react';
import { describe, expect, it } from 'vitest';
import { renderToStaticMarkup } from 'react-dom/server';
import { CorporateConsole } from '@/app/(console)/[city]/corporate/corporate-console';
import type {
  CorporateOverview,
  CorporatePolicyRow,
} from '@/lib/corporate/types';

const overview: CorporateOverview = {
  corporate_account_id: 'corp-1',
  account_name: 'Acme Corp',
  currency: 'NGN',
  monthly_budget: 50000,
  subsidy_used_mtd: 12000,
  enrolled_staff: 8,
  active_staff_trips: 3,
  live_trips: [
    {
      trip_id: 'trip-1',
      employee_ref: 'E-100',
      department: 'Ops',
      status: 'in_transit',
      mode_code: 'car',
      fare_shown: 450,
      requested_at: '2026-01-01T10:00:00Z',
    },
  ],
};

const policies: CorporatePolicyRow[] = [
  {
    id: 'pol-1',
    name: 'Standard 50%',
    subsidy_pct: 0.5,
    max_per_trip: 200,
    allowed_hours: null,
    active: true,
  },
];

describe('CorporateConsole role gating', () => {
  it('renders C-01 overview tabs for corporate_admin', () => {
    const html = renderToStaticMarkup(
      <CorporateConsole
        citySlug="abuja"
        overview={overview}
        members={[]}
        policies={policies}
        allocations={[]}
        invoices={[]}
        invoiceLinesByInvoice={{}}
        isCorporateAdmin
      />
    );
    expect(html).toContain('data-testid="corporate-console"');
    expect(html).toContain('data-testid="corporate-tab-overview"');
    expect(html).toContain('data-testid="corporate-tab-roster"');
    expect(html).toContain('data-testid="corporate-subsidy-mtd"');
    expect(html).toContain('data-testid="corporate-live-trips"');
  });

  it('blocks portal body when not corporate_admin', () => {
    const html = renderToStaticMarkup(
      <CorporateConsole
        citySlug="abuja"
        overview={null}
        members={[]}
        policies={[]}
        allocations={[]}
        invoices={[]}
        invoiceLinesByInvoice={{}}
        isCorporateAdmin={false}
      />
    );
    expect(html).toContain('data-testid="corporate-console-unscoped"');
    expect(html).not.toContain('data-testid="corporate-tab-roster"');
  });
});
