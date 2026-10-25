import { execSync } from 'node:child_process';
import { test, expect } from '@playwright/test';
import { E2E_CITY } from './global-setup';
import { signInAs } from './helpers';

// Fixtures go through psql like the other specs: the local stack no longer grants
// service_role DML on public tables by default, so PostgREST writes are denied.
const DATABASE_URL =
  process.env.DATABASE_URL ?? 'postgresql://postgres:postgres@127.0.0.1:54322/postgres';

const OPEN_SOS_ID = 'c5500000-0000-4000-8000-000000000001';
const LIVE_SOS_ID = 'c5500000-0000-4000-8000-000000000002';

function sqlScalar(query: string): string {
  return execSync(`psql "${DATABASE_URL}" -v ON_ERROR_STOP=1 -t -A -c ${JSON.stringify(query.replace(/\s+/g, ' '))}`, {
    encoding: 'utf8',
  }).trim();
}

async function sosStatus(sosId: string): Promise<string | null> {
  return sqlScalar(`select status from sos_alerts where id = '${sosId}'`) || null;
}

async function insertLiveSos(): Promise<void> {
  // One psql -c runs as one transaction, so the board's reload on the delete
  // event already sees the inserted row.
  sqlScalar(
    `delete from sos_alerts where id = '${LIVE_SOS_ID}';
     insert into sos_alerts (id, trip_id, journey_id, raised_by, raised_role, location, status, created_at)
     values ('${LIVE_SOS_ID}', null, 'c5300000-0000-4000-8000-000000000001',
             'c5000000-0000-4000-8000-000000000001', 'rider',
             'SRID=4326;POINT(7.597 9.014)', 'open', now())`
  );
}

test.describe('Safety board (A-12)', () => {
  test('simulated SOS visible on board; ack updates status', async ({ page }) => {
    // Idempotent across retries: the ack below flips the seeded alert.
    sqlScalar(`update sos_alerts set status = 'open', acknowledged_at = null, acknowledged_by = null where id = '${OPEN_SOS_ID}'`);
    await signInAs(page, 'e2e-safety@along.local', {
      landing: `/${E2E_CITY}/safety`,
    });

    await expect(page.getByRole('heading', { name: 'Safety board' })).toBeVisible();
    await expect(page.getByTestId('safety-board')).toBeVisible();
    await expect(page.getByTestId('safety-runbook-link')).toBeVisible();

    const seededRow = page.getByTestId(`safety-sos-row-${OPEN_SOS_ID}`);
    await expect(seededRow).toBeVisible();
    await expect(seededRow.getByText('open')).toBeVisible();

    // Insert only once the board is listening, or the change event is missed.
    await expect(page.getByTestId('safety-board')).toHaveAttribute('data-live-status', 'listening', {
      timeout: 15_000,
    });
    await insertLiveSos();
    await expect(page.getByTestId(`safety-sos-row-${LIVE_SOS_ID}`)).toBeVisible({
      timeout: 15_000,
    });

    await page.getByTestId(`safety-ack-${OPEN_SOS_ID}`).click();
    await expect(page.getByTestId('safety-success')).toBeVisible({ timeout: 15_000 });

    await expect
      .poll(async () => sosStatus(OPEN_SOS_ID), { timeout: 10_000 })
      .toBe('acknowledged');

    await expect(seededRow.locator('.badge-acknowledged')).toBeVisible();
  });
});
