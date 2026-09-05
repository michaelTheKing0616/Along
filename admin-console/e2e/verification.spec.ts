import { createClient } from '@supabase/supabase-js';
import { test, expect } from '@playwright/test';
import { E2E_CITY } from './global-setup';
import { signInAs } from './helpers';

const SUPABASE_URL = process.env.SUPABASE_URL ?? 'http://127.0.0.1:54321';
const SERVICE_ROLE_KEY =
  process.env.SUPABASE_SERVICE_ROLE_KEY ??
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU';

const APPROVE_ID = 'c2200000-0000-4000-8000-000000000010';
const REJECT_ID = 'c2200000-0000-4000-8000-000000000011';

async function countViewDocumentAudit(targetId: string): Promise<number> {
  const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { count, error } = await admin
    .from('audit_log')
    .select('*', { count: 'exact', head: true })
    .eq('action', 'view_document')
    .eq('target_id', targetId);
  if (error) throw new Error(error.message);
  return count ?? 0;
}

test.describe('Verification queue (A-04)', () => {
  test('verifier views document, approves one and rejects one with audit rows', async ({
    page,
  }) => {
    await signInAs(page, 'e2e-verifier@along.local', {
      landing: `/${E2E_CITY}/verification`,
    });

    await expect(page.getByRole('heading', { name: 'Verification' })).toBeVisible();
    await expect(page.getByTestId('verification-table')).toBeVisible();

    const approveRow = page.getByTestId(`verification-row-${APPROVE_ID}`);
    const rejectRow = page.getByTestId(`verification-row-${REJECT_ID}`);
    await expect(approveRow).toBeVisible();
    await expect(rejectRow).toBeVisible();

    await approveRow.click();
    await expect(page.getByTestId('verification-detail')).toBeVisible();
    await expect(page.getByTestId('women-only-eligible')).toBeVisible();

    const beforeViewAudit = await countViewDocumentAudit(APPROVE_ID);
    await page.getByTestId(`view-document-${APPROVE_ID}`).click();
    await expect(page.getByTestId('verification-doc-viewer')).toBeVisible({ timeout: 15_000 });
    await expect(page.getByTestId('verification-viewed-flag')).toBeVisible();

    await expect
      .poll(async () => countViewDocumentAudit(APPROVE_ID), { timeout: 10_000 })
      .toBeGreaterThan(beforeViewAudit);

    await page.getByTestId('women-only-eligible').check();
    await page.getByTestId('approve-verification').click();
    await expect(page.getByTestId('verification-success')).toBeVisible({ timeout: 15_000 });
    await expect(approveRow.getByText('approved')).toBeVisible();

    await rejectRow.click();
    await page.getByTestId('reject-reason').fill('Document unreadable in E2E test');
    await page.getByTestId('reject-verification').click();
    await expect(page.getByTestId('verification-success')).toBeVisible({ timeout: 15_000 });
    await expect(rejectRow.getByText('rejected')).toBeVisible();
  });
});
