import { readFileSync } from 'node:fs';
import path from 'node:path';
import { type Page, expect } from '@playwright/test';
import { authenticator } from 'otplib';
import { E2E_CITY, E2E_PASSWORD, type TotpSecrets } from './global-setup';

function loadTotpSecrets(): TotpSecrets {
  const file = path.join(process.cwd(), 'e2e', '.auth', 'totp-secrets.json');
  return JSON.parse(readFileSync(file, 'utf8')) as TotpSecrets;
}

async function completeMfaIfNeeded(page: Page, email: string) {
  if (!page.url().includes('/mfa')) return;

  const secrets = loadTotpSecrets();
  const secret = secrets[email];
  if (!secret) {
    throw new Error(`Missing TOTP secret for ${email}; re-run pnpm test:e2e:setup`);
  }

  const code = authenticator.generate(secret);
  await page.getByLabel('Authentication code').fill(code);
  await page.getByRole('button', { name: 'Verify' }).click();
}

function consolePathPattern(): RegExp {
  return /^\/(?:[^/]+\/)?(?:dashboard|finance|admins|verification|corrections|safety|audit|field|graph|deploy|unauthorized)(?:\/|$)/;
}

export async function signInAs(page: Page, email: string, options?: { landing?: string }) {
  const landing = options?.landing ?? `/${E2E_CITY}/dashboard`;

  await page.goto(`/sign-in?next=${encodeURIComponent(landing)}`);
  await page.getByLabel('Email').fill(email);
  await page.getByLabel('Password').fill(E2E_PASSWORD);
  await page.getByRole('button', { name: 'Sign in' }).click();

  await page.waitForURL((url) => {
    const path = new URL(url).pathname;
    return path === '/mfa' || consolePathPattern().test(path);
  });
  await completeMfaIfNeeded(page, email);

  if (!page.url().includes('/unauthorized')) {
    await expect(page).toHaveURL(new RegExp(`${landing.replace(/\//g, '\\/')}(?:/)?$`));
  }
}

export async function signOut(page: Page) {
  await page.getByRole('link', { name: 'Sign out' }).click();
  await expect(page).toHaveURL(/\/sign-in/);
}
