/**
 * P8-D-01 — Corporate / Operator / Revenue portals (Playwright optional).
 * Run when admin-console + seeded Supabase are available:
 *   npx playwright test e2e/b2b-portals.spec.ts
 */
import { test, expect } from '@playwright/test';

test.describe('P8-D-01 B2B portals', () => {
  test.skip(true, 'Requires admin-console against seeded Supabase — run manually in staging');

  test('corporate_admin can provision staff and view billing tabs', async ({ page }) => {
    await page.goto('/abuja/corporate');
    await expect(page.getByRole('heading', { name: 'Corporate portal' })).toBeVisible();
    await page.getByTestId('corporate-tab-roster').click();
    await expect(page.getByTestId('corporate-invite-phone')).toBeVisible();
    await page.getByTestId('corporate-tab-billing').click();
    await expect(page.getByTestId('corporate-billing')).toBeVisible();
  });

  test('operator_viewer sees aggregate overview without rider fields', async ({ page }) => {
    await page.goto('/abuja/operator');
    await expect(page.getByRole('heading', { name: 'Operator overview' })).toBeVisible();
    await expect(page.getByTestId('operator-online-total')).toBeVisible();
    const body = await page.locator('[data-testid="operator-console"]').innerText();
    expect(body.toLowerCase()).not.toContain('rider');
  });

  test('finance can create API key and sponsored placement', async ({ page }) => {
    await page.goto('/abuja/revenue');
    await expect(page.getByRole('heading', { name: 'Revenue hooks' })).toBeVisible();
    await page.getByTestId('revenue-tab-api-keys').click();
    await expect(page.getByTestId('revenue-api-create')).toBeVisible();
    await page.getByTestId('revenue-tab-placements').click();
    await expect(page.getByTestId('revenue-placement-submit')).toBeVisible();
  });
});
