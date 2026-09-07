/**
 * P10-D-01 — A-18 Markets & portability (Playwright optional).
 * Run when admin-console + seeded Supabase are available:
 *   npx playwright test e2e/markets-portability.spec.ts
 */
import { test, expect } from '@playwright/test';

test.describe('A-18 Markets & portability', () => {
  test.skip(true, 'Requires admin-console against seeded Supabase — run manually in staging');

  test('ops_lead can add hypothetical Ghana country config without code', async ({ page }) => {
    await page.goto('/abuja/markets');
    await expect(page.getByRole('heading', { name: 'Markets & portability' })).toBeVisible();
    await expect(page.getByTestId('markets-tab-countries')).toBeVisible();

    await page.getByTestId('markets-prefill-ghana').click();
    await expect(page.getByTestId('markets-new-code')).toHaveValue('GH');
    await expect(page.getByTestId('markets-new-currency')).toHaveValue('GHS');

    await page.getByTestId('markets-save-country').click();
    await expect(page.getByTestId('markets-success')).toBeVisible({ timeout: 10_000 });
    await expect(page.getByTestId('country-row-GH')).toBeVisible();
  });

  test('shows verification, regulatory, i18n, and payment tabs', async ({ page }) => {
    await page.goto('/abuja/markets');
    await page.getByTestId('markets-tab-verification').click();
    await expect(page.getByTestId('markets-verification')).toBeVisible();
    await page.getByTestId('markets-tab-regulatory').click();
    await expect(page.getByTestId('markets-regulatory')).toBeVisible();
    await page.getByTestId('markets-tab-i18n').click();
    await expect(page.getByTestId('markets-i18n')).toBeVisible();
    await page.getByTestId('markets-tab-payment').click();
    await expect(page.getByTestId('markets-payment')).toBeVisible();
  });
});
