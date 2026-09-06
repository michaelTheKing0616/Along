import { execSync } from 'node:child_process';
import { test, expect } from '@playwright/test';
import { E2E_CITY } from './global-setup';
import { signInAs, signOut } from './helpers';

const DATABASE_URL =
  process.env.DATABASE_URL ?? 'postgresql://postgres:postgres@127.0.0.1:54322/postgres';

const DRIVER_ID = 'd1000000-0000-4000-8000-000000000001';
const FINANCE_ONE = 'e2e-finance@along.local';
const FINANCE_TWO = 'e2e-finance2@along.local';

function sqlScalar(query: string): string {
  return execSync(`psql "${DATABASE_URL}" -t -A -c ${JSON.stringify(query)}`, {
    encoding: 'utf8',
  }).trim();
}

function pendingCount(): number {
  return Number(
    sqlScalar(
      `select count(*)::int from pending_ledger_adjustments where driver_id = '${DRIVER_ID}' and status = 'pending'`
    )
  );
}

test.describe('Finance dual control (A-13)', () => {
  test('second finance user approves above-threshold adjustment', async ({ page }) => {
    await signInAs(page, FINANCE_ONE, { landing: `/${E2E_CITY}/drivers/${DRIVER_ID}` });

    await page.getByTestId('driver-tab-ledger').click();
    await page.getByTestId('adjustment-amount').fill('25000');
    await page.getByTestId('adjustment-memo').fill('E2E dual-control adjustment');
    await page.getByTestId('submit-adjustment').click();
    await expect(page.getByTestId('driver-success')).toBeVisible({ timeout: 15_000 });

    await expect.poll(() => pendingCount(), { timeout: 10_000 }).toBe(1);

    await signOut(page);
    await signInAs(page, FINANCE_ONE, { landing: `/${E2E_CITY}/finance` });

    const pendingRow = page.locator('[data-testid^="pending-adjustment-"]').first();
    await expect(pendingRow).toBeVisible();
    const approveBtn = pendingRow.locator('[data-testid^="approve-adjustment-"]');
    await expect(approveBtn).toBeDisabled();

    await signOut(page);
    await signInAs(page, FINANCE_TWO, { landing: `/${E2E_CITY}/finance` });

    await expect(page.getByTestId('dual-control-queue')).toBeVisible();
    const pendingRowTwo = page.locator('[data-testid^="pending-adjustment-"]').first();
    await expect(pendingRowTwo).toBeVisible();
    await pendingRowTwo.locator('[data-testid^="approve-adjustment-"]').click();
    await expect(page.getByTestId('finance-success')).toBeVisible({ timeout: 15_000 });

    await expect.poll(() => pendingCount(), { timeout: 10_000 }).toBe(0);

    const ledgerCount = Number(
      sqlScalar(
        `select count(*)::int from driver_ledger_entries where driver_id = '${DRIVER_ID}' and entry_type = 'manual_adjustment'`
      )
    );
    expect(ledgerCount).toBe(1);
  });
});
