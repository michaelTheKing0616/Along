import { execSync } from 'node:child_process';
import path from 'node:path';
import { test, expect } from '@playwright/test';
import pdf from 'pdf-parse/lib/pdf-parse.js';
import { E2E_CITY } from './global-setup';
import { signInAs } from './helpers';

const DATABASE_URL =
  process.env.DATABASE_URL ?? 'postgresql://postgres:postgres@127.0.0.1:54322/postgres';
const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL ?? 'http://127.0.0.1:54321';

const DRIVER_CODE = 'W04TEST1';
const DRIVER_ID = 'd2000000-0000-4000-8000-000000000201';
const PLATE = 'W04-PLATE';
const FINANCE_USER = 'e2e-finance@along.local';
const MOCK_CHECKOUT = 'https://checkout.paystack.test/e2e-w04';
const W04_BUDGET_BYTES = 60 * 1024;

function sqlScalar(query: string): string {
  return execSync(`psql "${DATABASE_URL}" -t -A -c ${JSON.stringify(query)}`, {
    encoding: 'utf8',
  }).trim();
}

test.describe('W-04 anonymous web pay (TS-UI-06)', () => {
  test('not-enabled copy when digital flag is off', async ({ page }) => {
    sqlScalar(
      `delete from app_config where key = 'payments.digital_enabled' and scope_type = 'city' and scope_id = 'b1000000-0000-4000-8000-000000000001'`
    );

    await page.goto(`/p/${DRIVER_CODE}`);
    await expect(page.getByTestId('w04-not-enabled')).toBeVisible({ timeout: 15_000 });
    await expect(page.getByText('Digital pay unavailable')).toBeVisible();

    execSync(
      `psql "${DATABASE_URL}" -v ON_ERROR_STOP=1 -f "${path.join(process.cwd(), 'e2e', 'seed-w04-pay.sql')}"`
    );
  });

  test('2 taps to mocked Paystack checkout; payload ≤ 60 KB', async ({ page }) => {
    let initiateCalled = false;

    await page.route(`${SUPABASE_URL}/functions/v1/payments/initiate`, async (route) => {
      initiateCalled = true;
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          data: {
            payment_id: 'e2e-mock-payment',
            authorization_url: MOCK_CHECKOUT,
            amount: 500,
            commission_amount: 37.5,
            driver_amount: 462.5,
            receipt_token: 'e2e-receipt-token',
          },
          meta: { request_id: 'e2e' },
        }),
      });
    });

    await page.route(MOCK_CHECKOUT, async (route) => {
      await route.fulfill({
        status: 200,
        contentType: 'text/html',
        body: '<html><body data-testid="mock-paystack-checkout">Mock Paystack</body></html>',
      });
    });

    const response = await page.goto(`/p/${DRIVER_CODE}`);
    const htmlBytes = (await response?.body())?.length ?? 0;
    expect(htmlBytes).toBeLessThanOrEqual(W04_BUDGET_BYTES);
    expect(htmlBytes).toBeGreaterThan(0);

    await expect(page.getByTestId('w04-pay')).toBeVisible({ timeout: 15_000 });
    await expect(page.getByTestId('w04-plate')).toHaveText(PLATE);
    await expect(page.getByTestId('w04-driver-name')).toContainText('Musa');

    await page.locator('[data-testid^="w04-chip-"]').first().click();
    await page.getByTestId('w04-pay-btn').click();

    await expect(page.getByTestId('mock-paystack-checkout')).toBeVisible({ timeout: 15_000 });
    expect(initiateCalled).toBe(true);
  });
});

test.describe('A-13 sticker batch PDF', () => {
  test('PDF preview contains plate, driver code, and QR image', async ({ page }) => {
    await signInAs(page, FINANCE_USER, { landing: `/${E2E_CITY}/finance` });
    await page.getByTestId(`sticker-select-${DRIVER_CODE}`).check();

    const exportResponsePromise = page.waitForResponse(
      (res) => res.url().includes('/api/finance/sticker-batch') && res.status() === 200
    );
    await page.getByTestId('export-sticker-batch').click();
    const exportResponse = await exportResponsePromise;
    const pdfBytes = Buffer.from(await exportResponse.body());
    const parsed = await pdf(pdfBytes);

    expect(parsed.text).toContain(PLATE);
    expect(parsed.text).toContain(DRIVER_CODE);
    expect(parsed.text).toContain('STAGING');
    expect(pdfBytes.length).toBeGreaterThan(500);
    expect(pdfBytes.subarray(0, 4).toString()).toBe('%PDF');
    expect(pdfBytes.toString('latin1')).toMatch(/\/Image|\/XObject/);
  });
});

test.describe('A-11 driver payments tab', () => {
  test('shows code, subaccount, and QR payment row', async ({ page }) => {
    await signInAs(page, FINANCE_USER, { landing: `/${E2E_CITY}/drivers/${DRIVER_ID}` });
    await page.getByTestId('driver-tab-payments').click();
    await expect(page.getByTestId('driver-payments-code')).toHaveText(DRIVER_CODE);
    await expect(page.getByTestId('driver-payments-subaccount')).toHaveText('Active');
    await expect(page.getByTestId('driver-qr-payments')).toBeVisible();
  });
});
