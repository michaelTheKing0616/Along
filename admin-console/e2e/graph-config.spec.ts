import { execSync } from 'node:child_process';
import { test, expect } from '@playwright/test';
import { E2E_CITY } from './global-setup';
import { signInAs } from './helpers';

const DATABASE_URL =
  process.env.DATABASE_URL ?? 'postgresql://postgres:postgres@127.0.0.1:54322/postgres';

const PARK_ID = 'b1100000-0000-4000-8000-000000000001';
const OPS_AGENT_ID = 'b0000000-0000-4000-8000-000000000105';

function sqlScalar(query: string): string {
  return execSync(`psql "${DATABASE_URL}" -t -A -c ${JSON.stringify(query)}`, {
    encoding: 'utf8',
  }).trim();
}

function revisionCountForPark(): number {
  return Number(
    sqlScalar(
      `select count(*)::int from graph_revisions where target_type = 'parks' and target_id = '${PARK_ID}'`
    )
  );
}

function latestAuditReasonForConfig(key: string, scope: string, scopeId: string): string {
  return sqlScalar(
    `select coalesce(after->>'reason','') from audit_log where target_type = 'app_config' and target_id = '${key}:${scope}:${scopeId}' order by created_at desc, id desc limit 1`
  );
}

test.describe('Graph editor (A-05)', () => {
  test('ops_agent save writes graph_revisions and audit via RPC', async ({ page }) => {
    const beforeRevisions = revisionCountForPark();
    const beforeAudit = Number(
      sqlScalar(
        `select count(*)::int from audit_log where target_type = 'parks' and target_id = '${PARK_ID}'`
      )
    );

    await signInAs(page, 'e2e-ops-agent@along.local');
    await page.goto(`/${E2E_CITY}/graph`);

    await expect(page.getByTestId('graph-editor')).toBeVisible();
    await page.getByTestId(`graph-park-${PARK_ID}`).click();
    await page.getByTestId('graph-edit-name').fill('Nyanya Park E2E');
    await page.getByTestId('graph-queue-change').click();
    await page.getByTestId(`graph-save-park-${PARK_ID}`).click();

    await expect(page.getByTestId('graph-success')).toBeVisible({ timeout: 15_000 });
    await expect(page.getByTestId('graph-success')).toContainText('graph revision');

    await expect.poll(() => revisionCountForPark(), { timeout: 10_000 }).toBeGreaterThan(
      beforeRevisions
    );

    const afterAudit = Number(
      sqlScalar(
        `select count(*)::int from audit_log where target_type = 'parks' and target_id = '${PARK_ID}'`
      )
    );
    expect(afterAudit).toBeGreaterThan(beforeAudit);

    const actor = sqlScalar(
      `select actor_id::text from audit_log where target_type = 'parks' and target_id = '${PARK_ID}' order by created_at desc, id desc limit 1`
    );
    expect(actor).toBe(OPS_AGENT_ID);
  });
});

test.describe('Config editor (A-09)', () => {
  test('superadmin config change requires reason and writes audit', async ({ page }) => {
    const targetId = 'graph.snap_radius_m:global:*';
    const reason = 'E2E widen snap radius for graph editor QA';

    await signInAs(page, 'e2e-superadmin@along.local', { landing: `/${E2E_CITY}/config` });
    await expect(page.getByTestId('config-editor')).toBeVisible({ timeout: 15_000 });

    await page.getByTestId('config-key-graph.snap_radius_m').click();
    await page.getByTestId('config-scope-global').click();
    await page.getByTestId('config-value-input').fill('65');
    await page.getByTestId('config-save').click();
    await expect(page.getByText('Reason is required')).toBeVisible();

    await page.getByTestId('config-reason').fill(reason);
    await page.getByTestId('config-save').click();
    await expect(page.getByTestId('config-success')).toBeVisible({ timeout: 15_000 });

    await expect.poll(() => latestAuditReasonForConfig('graph.snap_radius_m', 'global', '*'), {
      timeout: 10_000,
    }).toBe(reason);

    const cfgValue = sqlScalar(
      `select value::text from app_config where key = 'graph.snap_radius_m' and scope_type = 'global' and scope_id = '*'`
    );
    expect(cfgValue).toBe('65');

    const auditTarget = sqlScalar(
      `select target_id from audit_log where target_type = 'app_config' and target_id = '${targetId}' order by created_at desc, id desc limit 1`
    );
    expect(auditTarget).toBe(targetId);
  });
});
