import { test, expect } from '@playwright/test';

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL ?? 'http://127.0.0.1:54321';
const SHARE_TOKEN = 'e2e-share-token';

const MOCK_PAYLOAD = {
  rider_first_name: 'Share',
  status: 'in_transit',
  mode: { code: 'keke', label: 'Keke' },
  vehicle: { plate: 'SHR-01', color: 'Yellow' },
  driver_first_name: 'Musa',
  current_location: { lat: 9.05, lng: 7.49 },
  destination_label: 'Area 1',
  eta_s: 420,
  legs_progress: [{ sequence: 1, status: 'current', label: 'Lugbe → Area 1' }],
};

test.describe('W-01 shared trip (minimal disclosure)', () => {
  test('shows allowed fields only; no phone in DOM', async ({ page }) => {
    await page.route(`${SUPABASE_URL}/rest/v1/rpc/shared_trip_view`, async (route) => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(MOCK_PAYLOAD),
      });
    });

    await page.goto(`/s/${SHARE_TOKEN}`);
    await expect(page.getByTestId('w01-shared-trip')).toBeVisible({ timeout: 15_000 });
    await expect(page.getByTestId('w01-rider-first-name')).toHaveText('Share');
    await expect(page.getByTestId('w01-plate')).toHaveText('SHR-01');
    await expect(page.getByTestId('w01-color')).toHaveText('Yellow');
    await expect(page.getByTestId('w01-mode')).toHaveText('Keke');
    await expect(page.getByTestId('w01-live-marker')).toBeVisible();
    await expect(page.getByTestId('w01-destination')).toHaveText('Area 1');
    await expect(page.getByTestId('w01-eta')).toHaveText('7 min');
    await expect(page.getByTestId('w01-leg-0')).toContainText('Lugbe → Area 1');

    const html = await page.content();
    expect(html).not.toMatch(/\+234/);
    expect(html).not.toContain('driver_first_name');
    expect(html).not.toContain('Musa');
  });
});
