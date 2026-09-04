import { defineConfig, devices } from '@playwright/test';
import { existsSync } from 'node:fs';

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL ?? 'http://127.0.0.1:54321';
const SUPABASE_ANON_KEY =
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ??
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW9sZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';

const chromePaths = [
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  '/Applications/Chromium.app/Contents/MacOS/Chromium',
];
const executablePath = chromePaths.find((p) => existsSync(p));

export default defineConfig({
  testDir: './e2e',
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  workers: 1,
  reporter: 'list',
  timeout: 60_000,
  use: {
    baseURL: 'http://127.0.0.1:3000',
    trace: 'on-first-retry',
    headless: true,
    ...(executablePath ? { launchOptions: { executablePath } } : {}),
  },
  ...(process.env.CI
    ? {
        webServer: {
          command: 'pnpm start',
          url: 'http://127.0.0.1:3000',
          timeout: 60_000,
          env: {
            NEXT_PUBLIC_SUPABASE_URL: SUPABASE_URL,
            NEXT_PUBLIC_SUPABASE_ANON_KEY: SUPABASE_ANON_KEY,
          },
        },
      }
    : {}),
  projects: [
    {
      name: 'chrome',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
});
