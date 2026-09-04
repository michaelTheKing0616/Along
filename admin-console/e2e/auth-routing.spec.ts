import { test, expect } from '@playwright/test';
import { E2E_CITY, TEST_USERS } from './global-setup';
import { signInAs } from './helpers';

test.describe('Admin sign-in per role', () => {
  for (const user of TEST_USERS) {
    test(`${user.role} can sign in`, async ({ page }) => {
      await signInAs(page, user.email);
      await expect(page.getByRole('heading', { name: 'Dashboard' })).toBeVisible();
      await expect(page.getByText(`City: ${E2E_CITY}`)).toBeVisible();
    });
  }
});

test.describe('Unauthorized route redirect', () => {
  test('verifier is redirected from finance route', async ({ page }) => {
    await signInAs(page, 'e2e-verifier@along.local');
    await page.goto(`/${E2E_CITY}/finance`);
    await expect(page).toHaveURL(/\/unauthorized/);
    await expect(page.getByRole('heading', { name: 'Unauthorized' })).toBeVisible();
  });

  test('analyst is redirected from admins route', async ({ page }) => {
    await signInAs(page, 'e2e-analyst@along.local');
    await page.goto(`/${E2E_CITY}/admins`);
    await expect(page).toHaveURL(/\/unauthorized/);
  });

  test('finance can access finance route', async ({ page }) => {
    await signInAs(page, 'e2e-finance@along.local', { landing: `/${E2E_CITY}/finance` });
    await expect(page.getByRole('heading', { name: 'Finance' })).toBeVisible();
  });

  test('superadmin can access admins route', async ({ page }) => {
    await signInAs(page, 'e2e-superadmin@along.local', { landing: `/${E2E_CITY}/admins` });
    await expect(page.getByRole('heading', { name: 'Admin users' })).toBeVisible();
  });

  test('ops_agent is redirected from finance route', async ({ page }) => {
    await signInAs(page, 'e2e-ops-agent@along.local');
    await page.goto(`/${E2E_CITY}/finance`);
    await expect(page).toHaveURL(/\/unauthorized/);
  });
});
