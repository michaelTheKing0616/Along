import { execSync } from 'node:child_process';
import { test, expect } from '@playwright/test';
import { E2E_CITY } from './global-setup';
import { signInAs } from './helpers';

const DATABASE_URL =
  process.env.DATABASE_URL ?? 'postgresql://postgres:postgres@127.0.0.1:54322/postgres';

const APPROVE_ID = 'c2400000-0000-4000-8000-000000000010';
const REJECT_ID = 'c2400000-0000-4000-8000-000000000011';
const MAD_ID = 'c2400000-0000-4000-8000-000000000012';
const NEGOTIATION_ID = 'c2400000-0000-4000-8000-000000000013';
const CANDIDATE_LEG_ID = 'c2300000-0000-4000-8000-000000000010';

function sqlScalar(query: string): string {
  return execSync(`psql "${DATABASE_URL}" -t -A -c ${JSON.stringify(query)}`, {
    encoding: 'utf8',
  }).trim();
}

function countConfirmations(targetId: string): number {
  return Number(
    sqlScalar(
      `select count(*)::int from graph_confirmations where target_type = 'route_leg' and target_id = '${targetId}'`
    )
  );
}

function legVerificationStatus(legId: string): string | null {
  const value = sqlScalar(
    `select verification_status::text from route_legs where id = '${legId}'`
  );
  return value || null;
}

test.describe('Fare corrections queue (A-06)', () => {
  test('ops agent approves correction → confirmation row + promotion', async ({ page }) => {
    await signInAs(page, 'e2e-ops-agent@along.local', {
      landing: `/${E2E_CITY}/corrections`,
    });

    await expect(page.getByRole('heading', { name: 'Fare corrections' })).toBeVisible();
    await expect(page.getByTestId('corrections-table')).toBeVisible();

    await expect(page.getByTestId(`mad-badge-${MAD_ID}`)).toBeVisible();
    await expect(page.getByTestId(`negotiation-badge-${NEGOTIATION_ID}`)).toBeVisible();

    const approveRow = page.getByTestId(`correction-row-${APPROVE_ID}`);
    const rejectRow = page.getByTestId(`correction-row-${REJECT_ID}`);
    await expect(approveRow).toBeVisible();
    await expect(rejectRow).toBeVisible();

    await approveRow.click();
    await expect(page.getByTestId('correction-detail')).toBeVisible();
    await expect(page.getByTestId('submitter-trust')).toBeVisible();

    const beforeConfirmations = countConfirmations(CANDIDATE_LEG_ID);
    expect(beforeConfirmations).toBe(2);

    await page.getByTestId('approve-correction').click();
    await expect(page.getByTestId('corrections-success')).toBeVisible({ timeout: 15_000 });
    await expect(approveRow.getByText('approved')).toBeVisible();

    await expect
      .poll(() => countConfirmations(CANDIDATE_LEG_ID), { timeout: 10_000 })
      .toBe(3);

    await expect
      .poll(() => legVerificationStatus(CANDIDATE_LEG_ID), { timeout: 10_000 })
      .toBe('crowd_verified');

    await rejectRow.click();
    await page.getByTestId('correction-note').fill('Out of band for E2E test');
    await page.getByTestId('reject-correction').click();
    await expect(page.getByTestId('corrections-success')).toBeVisible({ timeout: 15_000 });
    await expect(rejectRow.getByText('rejected')).toBeVisible();
  });
});
