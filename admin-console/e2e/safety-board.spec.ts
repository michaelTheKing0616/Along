import { createClient } from '@supabase/supabase-js';
import { test, expect } from '@playwright/test';
import { E2E_CITY } from './global-setup';
import { signInAs } from './helpers';

const SUPABASE_URL = process.env.SUPABASE_URL ?? 'http://127.0.0.1:54321';
const SERVICE_ROLE_KEY =
  process.env.SUPABASE_SERVICE_ROLE_KEY ??
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU';

const OPEN_SOS_ID = 'c5500000-0000-4000-8000-000000000001';
const LIVE_SOS_ID = 'c5500000-0000-4000-8000-000000000002';

async function sosStatus(sosId: string): Promise<string | null> {
  const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data, error } = await admin
    .from('sos_alerts')
    .select('status')
    .eq('id', sosId)
    .maybeSingle();
  if (error) throw new Error(error.message);
  return data?.status ?? null;
}

async function insertLiveSos(): Promise<void> {
  const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  await admin.from('sos_alerts').delete().eq('id', LIVE_SOS_ID);
  const { error } = await admin.from('sos_alerts').insert({
    id: LIVE_SOS_ID,
    trip_id: null,
    journey_id: 'c5300000-0000-4000-8000-000000000001',
    raised_by: 'c5000000-0000-4000-8000-000000000001',
    raised_role: 'rider',
    location: { type: 'Point', coordinates: [7.597, 9.014] },
    status: 'open',
    created_at: new Date().toISOString(),
  });
  if (error) throw new Error(error.message);
}

test.describe('Safety board (A-12)', () => {
  test('simulated SOS visible on board; ack updates status', async ({ page }) => {
    await signInAs(page, 'e2e-safety@along.local', {
      landing: `/${E2E_CITY}/safety`,
    });

    await expect(page.getByRole('heading', { name: 'Safety board' })).toBeVisible();
    await expect(page.getByTestId('safety-board')).toBeVisible();
    await expect(page.getByTestId('safety-runbook-link')).toBeVisible();

    const seededRow = page.getByTestId(`safety-sos-row-${OPEN_SOS_ID}`);
    await expect(seededRow).toBeVisible();
    await expect(seededRow.getByText('open')).toBeVisible();

    await insertLiveSos();
    await expect(page.getByTestId(`safety-sos-row-${LIVE_SOS_ID}`)).toBeVisible({
      timeout: 15_000,
    });

    await page.getByTestId(`safety-ack-${OPEN_SOS_ID}`).click();
    await expect(page.getByTestId('safety-success')).toBeVisible({ timeout: 15_000 });

    await expect
      .poll(async () => sosStatus(OPEN_SOS_ID), { timeout: 10_000 })
      .toBe('acknowledged');

    await expect(seededRow.getByText('acknowledged')).toBeVisible();
  });
});
