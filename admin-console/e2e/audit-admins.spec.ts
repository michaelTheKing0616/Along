import { execSync } from 'node:child_process';
import { test, expect } from '@playwright/test';
import { E2E_CITY } from './global-setup';
import { signInAs } from './helpers';

const DATABASE_URL =
  process.env.DATABASE_URL ?? 'postgresql://postgres:postgres@127.0.0.1:54322/postgres';

function sqlScalar(query: string): string {
  return execSync(`psql "${DATABASE_URL}" -t -A -c ${JSON.stringify(query)}`, {
    encoding: 'utf8',
  }).trim();
}

test.describe('Audit log viewer (A-16)', () => {
  test('ops_lead can browse paginated audit log and inspect JSON diff', async ({ page }) => {
    await signInAs(page, 'e2e-superadmin@along.local', { landing: `/${E2E_CITY}/audit` });
    await expect(page.getByTestId('audit-viewer')).toBeVisible();
    await expect(page.getByTestId('audit-row').first()).toBeVisible();

    await page.getByTestId('audit-filter-target-type').fill('app_config');
    await page.getByTestId('audit-apply-filters').click();
    await expect(page.getByTestId('audit-row').first()).toBeVisible();

    await page.getByTestId('audit-row').first().click();
    await expect(page.getByTestId('audit-diff-panel')).toBeVisible();
    await expect(page.getByTestId('audit-diff-after')).not.toHaveText('—');
  });

  test('finance can access audit route', async ({ page }) => {
    await signInAs(page, 'e2e-finance@along.local', { landing: `/${E2E_CITY}/audit` });
    await expect(page.getByRole('heading', { name: 'Audit log' })).toBeVisible();
  });
});

test.describe('Admin users (A-17)', () => {
  test('superadmin invites admin and disable writes audit row', async ({ page }) => {
    const email = `e2e-invited-${Date.now()}@along.local`;

    await signInAs(page, 'e2e-superadmin@along.local', { landing: `/${E2E_CITY}/admins` });
    await expect(page.getByTestId('admins-console')).toBeVisible();

    await page.getByTestId('admins-invite-email').fill(email);
    await page.getByTestId('admins-invite-name').fill('E2E Invited');
    await page.getByTestId('admins-invite-role').selectOption('analyst');
    await page.getByTestId('admins-invite-submit').click();

    await expect(page.getByTestId('admins-success')).toBeVisible({ timeout: 15_000 });
    await expect(page.getByRole('cell', { name: email })).toBeVisible();

    const userId = sqlScalar(
      `select id::text from auth.users where email = '${email}' limit 1`
    );
    expect(userId).not.toBe('');

    const totpCell = page.getByTestId('admin-user-row').filter({ hasText: email }).getByTestId('admin-totp-status');
    await expect(totpCell).toContainText('Not required');

    const auditCount = Number(
      sqlScalar(
        `select count(*)::int from audit_log where target_type = 'admin_users' and target_id = '${userId}' and action = 'insert'`
      )
    );
    expect(auditCount).toBeGreaterThan(0);

    await page.getByTestId('admin-user-row').filter({ hasText: email }).click();
    await page.getByTestId('admins-disable').click();
    await expect(page.getByTestId('admins-success')).toContainText('disabled', { timeout: 15_000 });

    const disabledAt = sqlScalar(
      `select disabled_at is not null from admin_users where id = '${userId}'`
    );
    expect(disabledAt).toBe('t');
  });
});
