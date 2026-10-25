import { execSync } from 'node:child_process';
import { test, expect } from '@playwright/test';
import { E2E_CITY } from './global-setup';
import { signInAs } from './helpers';

// psql, not a service_role client: the local stack denies service_role reads on audit_log.
const DATABASE_URL =
  process.env.DATABASE_URL ?? 'postgresql://postgres:postgres@127.0.0.1:54322/postgres';

const APPROVE_ID = 'c2200000-0000-4000-8000-000000000010';
const REJECT_ID = 'c2200000-0000-4000-8000-000000000011';

async function countViewDocumentAudit(targetId: string): Promise<number> {
  const out = execSync(
    `psql "${DATABASE_URL}" -v ON_ERROR_STOP=1 -t -A -c "select count(*) from audit_log where action = 'view_document' and target_id = '${targetId}'"`,
    { encoding: 'utf8' }
  ).trim();
  return Number(out);
}

test.describe('Verification queue (A-04)', () => {
  test('verifier views document, approves one and rejects one with audit rows', async ({
    page,
  }) => {
    await signInAs(page, 'e2e-verifier@along.local', {
      landing: `/${E2E_CITY}/verification`,
    });

    await expect(page.getByRole('heading', { name: 'Verification', exact: true })).toBeVisible();
    await expect(page.getByTestId('verification-table')).toBeVisible();

    const approveRow = page.getByTestId(`verification-row-${APPROVE_ID}`);
    const rejectRow = page.getByTestId(`verification-row-${REJECT_ID}`);
    await expect(approveRow).toBeVisible();
    await expect(rejectRow).toBeVisible();

    await approveRow.click();
    await expect(page.getByTestId('verification-detail')).toBeVisible();
    await expect(page.getByTestId('women-only-eligible')).toBeVisible();

    const beforeViewAudit = await countViewDocumentAudit(APPROVE_ID);
    await page.getByTestId(`view-document-${APPROVE_ID}`).click();
    await expect(page.getByTestId('verification-doc-viewer')).toBeVisible({ timeout: 15_000 });
    await expect(page.getByTestId('verification-viewed-flag')).toBeVisible();

    await expect
      .poll(async () => countViewDocumentAudit(APPROVE_ID), { timeout: 10_000 })
      .toBeGreaterThan(beforeViewAudit);

    await page.getByTestId('women-only-eligible').check();
    await page.getByTestId('approve-verification').click();
    await expect(page.getByTestId('verification-success')).toBeVisible({ timeout: 15_000 });
    await expect(approveRow.getByText('approved')).toBeVisible();

    await rejectRow.click();
    await page.getByTestId('reject-reason').fill('Document unreadable in E2E test');
    await page.getByTestId('reject-verification').click();
    await expect(page.getByTestId('verification-success')).toBeVisible({ timeout: 15_000 });
    await expect(rejectRow.getByText('rejected')).toBeVisible();
  });
});
