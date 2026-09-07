/**
 * W-03 legal pages — public, no auth (P12-E-02).
 * Skip in CI when PLAYWRIGHT_SKIP_LEGAL=1 (optional gate).
 */
import { test, expect } from '@playwright/test';

const skipLegal = process.env.PLAYWRIGHT_SKIP_LEGAL === '1';

test.describe('W-03 legal pages', () => {
  test.skip(skipLegal, 'PLAYWRIGHT_SKIP_LEGAL=1');

  test('terms page loads without sign-in', async ({ page }) => {
    await page.goto('/legal/terms');
    await expect(page.getByTestId('w03-terms')).toBeVisible();
    await expect(page.getByTestId('w03-draft-notice')).toContainText('not counsel-approved');
    await expect(page.getByTestId('w03-digital-off-notice')).toContainText('off by default');
    await expect(page).not.toHaveURL(/sign-in/);
  });

  test('privacy page loads without sign-in', async ({ page }) => {
    await page.goto('/legal/privacy');
    await expect(page.getByTestId('w03-privacy')).toBeVisible();
    await expect(page.getByTestId('w03-privacy-digital-off')).toContainText('off by default');
    await expect(page).not.toHaveURL(/sign-in/);
  });

  test('legal nav links cross-reference terms and privacy', async ({ page }) => {
    await page.goto('/legal/terms');
    await page.getByRole('link', { name: 'Privacy Notice' }).click();
    await expect(page).toHaveURL(/\/legal\/privacy/);
    await page.getByRole('link', { name: 'Terms of Service' }).click();
    await expect(page).toHaveURL(/\/legal\/terms/);
  });
});
