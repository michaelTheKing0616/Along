import { execSync } from 'node:child_process';
import { test, expect } from '@playwright/test';
import { signInAs, signInAsAgent } from './helpers';

const DATABASE_URL =
  process.env.DATABASE_URL ?? 'postgresql://postgres:postgres@127.0.0.1:54322/postgres';

const AGENT_EMAIL = 'e2e-settlement-agent@along.local';
const DRIVER_ID = 'a0000000-0000-4000-8000-000000000002';
const SETTLEMENT_AMOUNT = 3500;

function sqlScalar(query: string): string {
  return execSync(`psql "${DATABASE_URL}" -t -A -c ${JSON.stringify(query)}`, {
    encoding: 'utf8',
  }).trim();
}

function createDriverAgentCode(amount: number): string {
  const script = `
begin;
select set_config('request.jwt.claim.sub', '${DRIVER_ID}', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;
select create_agent_code(${amount})->>'agent_code';
commit;
`;
  const output = execSync(`psql "${DATABASE_URL}" -1 -t -A`, {
    encoding: 'utf8',
    input: script,
  }).trim();
  const code = output
    .split('\n')
    .map((line) => line.trim())
    .find((line) => /^[A-Z0-9]{6}$/.test(line));
  if (!code) throw new Error(`create_agent_code returned no code; output: ${output}`);
  return code;
}

function confirmedSettlementCount(agentCode: string): number {
  return Number(
    sqlScalar(
      `select count(*)::int from settlements where agent_code = '${agentCode}' and status = 'confirmed'`
    )
  );
}

test.describe('Agent settlement (P4-E-01)', () => {
  test('redeem succeeds once; replay rejected', async ({ page }) => {
    const agentCode = createDriverAgentCode(SETTLEMENT_AMOUNT);
    expect(agentCode).toMatch(/^[A-Z0-9]{6}$/);

    await signInAsAgent(page, AGENT_EMAIL);

    await expect(page.getByRole('heading', { name: 'Redeem settlement code' })).toBeVisible();
    await expect(page.getByText('E2E Abuja POS')).toBeVisible();

    await page.getByTestId('agent-code-input').fill(agentCode);
    await page.getByTestId('agent-amount-input').fill(String(SETTLEMENT_AMOUNT));
    await page.getByTestId('agent-submit').click();

    await expect(page.getByTestId('agent-success')).toBeVisible({ timeout: 15_000 });
    await expect(page.getByText(/Credit posted/)).toBeVisible();
    await expect.poll(() => confirmedSettlementCount(agentCode), { timeout: 10_000 }).toBe(1);

    await page.getByTestId('agent-code-input').fill(agentCode);
    await page.getByTestId('agent-amount-input').fill(String(SETTLEMENT_AMOUNT));
    await page.getByTestId('agent-submit').click();

    await expect(page.getByTestId('agent-error')).toBeVisible({ timeout: 15_000 });
    await expect(page.getByTestId('agent-error')).toContainText(/already redeemed/i);
    await expect.poll(() => confirmedSettlementCount(agentCode)).toBe(1);
  });

  test('admin user sees forbidden on agent surface', async ({ page }) => {
    await signInAs(page, 'e2e-finance@along.local', { landing: '/agent' });
    await expect(page.getByTestId('agent-forbidden')).toBeVisible();
    await expect(page.getByRole('heading', { name: 'Forbidden' })).toBeVisible();
  });
});
