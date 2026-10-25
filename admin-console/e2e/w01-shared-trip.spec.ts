import { execSync } from 'node:child_process';
import { test, expect } from '@playwright/test';

// Real fixture: e2e/seed-shared-trip.sql (the page resolves the token server-side).
const SHARE_TOKEN = 'e2e-share-token';
const DRIVER_ID = '0e200000-0000-4000-8000-000000000011';
const DATABASE_URL =
  process.env.DATABASE_URL ?? 'postgresql://postgres:postgres@127.0.0.1:54322/postgres';

// shared_trip_view only serves a location pinged in the last 30 s.
function pingDriver(): void {
  execSync(
    `psql "${DATABASE_URL}" -v ON_ERROR_STOP=1 -c "update driver_presence set last_ping_at = now() where driver_id = '${DRIVER_ID}'"`
  );
}

test.describe('W-01 shared trip (minimal disclosure)', () => {
  test('shows allowed fields only; no phone in DOM', async ({ page }) => {
    pingDriver();
    await page.goto(`/s/${SHARE_TOKEN}`);
    await expect(page.getByTestId('w01-shared-trip')).toBeVisible({ timeout: 15_000 });
    await expect(page.getByTestId('w01-rider-first-name')).toHaveText('Share');
    await expect(page.getByTestId('w01-plate')).toHaveText('SHR-01');
    await expect(page.getByTestId('w01-color')).toHaveText('Yellow');
    await expect(page.getByTestId('w01-mode')).toHaveText('Keke');
    await expect(page.getByTestId('w01-live-marker')).toBeVisible();
    await expect(page.getByTestId('w01-destination')).toHaveText('Area 1');
    await expect(page.getByTestId('w01-eta')).toHaveText('7 min');
    await expect(page.getByTestId('w01-leg-0')).toContainText('Leg 1');

    const html = await page.content();
    expect(html).not.toMatch(/\+234/);
    expect(html).not.toContain('driver_first_name');
    expect(html).not.toContain('Musa');
  });
});
