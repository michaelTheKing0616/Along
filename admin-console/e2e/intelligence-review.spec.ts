/**
 * P7-D-01 — A-14 Intelligence review (Playwright optional).
 * Run when admin-console + seeded Supabase are available:
 *   npx playwright test e2e/intelligence-review.spec.ts
 */
import { test, expect } from '@playwright/test';

test.describe('A-14 Intelligence review', () => {
  test.skip(true, 'Requires admin-console against seeded Supabase — run manually in staging');

  test('ops_lead can open intelligence tabs', async ({ page }) => {
    await page.goto('/abuja/intelligence');
    await expect(page.getByRole('heading', { name: 'Intelligence review' })).toBeVisible();
    await expect(page.getByTestId('intelligence-tab-parks')).toBeVisible();
    await expect(page.getByTestId('intelligence-tab-routes')).toBeVisible();
    await expect(page.getByTestId('intelligence-tab-geometry')).toBeVisible();
  });
});
