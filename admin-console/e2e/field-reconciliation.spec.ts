import { test, expect } from '@playwright/test';
import { E2E_CITY } from './global-setup';
import { signInAs } from './helpers';

test.describe('Field reconciliation (A-07)', () => {
  test('ops_agent reconciles two scouts and publishes to field_verified without SQL', async ({
    page,
  }) => {
    await signInAs(page, 'e2e-ops-agent@along.local');
    await page.goto(`/${E2E_CITY}/field`);

    await expect(page.getByRole('heading', { name: 'Field reconciliation' })).toBeVisible();
    await expect(page.getByTestId('field-reconciliation-table')).toBeVisible();

    const entityRow = page.getByTestId('field-row-park:abuja:e2e-reconcile-park');
    await expect(entityRow).toBeVisible();
    await entityRow.click();

    await expect(page.getByTestId('field-detail')).toBeVisible();
    await expect(page.getByText('Scout A')).toBeVisible();
    await expect(page.getByText('Scout B')).toBeVisible();
    await expect(page.getByText('matched')).toBeVisible();

    await page.getByTestId('publish-field-entity').click();
    await expect(page.getByTestId('field-success')).toBeVisible({ timeout: 15_000 });
    await expect(page.getByTestId('field-success')).toContainText('field_verified');
    await expect(page.getByTestId('field-published-status')).toBeVisible();
  });
});

test.describe('Graph editor (A-05)', () => {
  test('ops_agent can open graph editor', async ({ page }) => {
    await signInAs(page, 'e2e-ops-agent@along.local');
    await page.goto(`/${E2E_CITY}/graph`);
    await expect(page.getByRole('heading', { name: 'Graph editor' })).toBeVisible();
    await expect(page.getByTestId('graph-editor')).toBeVisible();
  });
});

test.describe('City deployment playbook (A-08)', () => {
  test('ops_lead can open deploy playbook and run CSV dry-run', async ({ page }) => {
    await signInAs(page, 'e2e-superadmin@along.local');
    await page.goto(`/${E2E_CITY}/deploy`);
    await expect(page.getByRole('heading', { name: 'City deployment playbook' })).toBeVisible({
      timeout: 15_000,
    });
    await page.getByTestId('deploy-csv-input').fill(
      'name,lat,lng\nDeploy Dry Run Park,9.070,7.420'
    );
    await page.getByTestId('deploy-dry-run').click();
    await expect(page.getByTestId('deploy-diff-table')).toBeVisible();
    await expect(page.getByTestId('deploy-diff-create-Deploy Dry Run Park')).toBeVisible();
  });
});
