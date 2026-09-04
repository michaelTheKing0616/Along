import { readFileSync, existsSync } from 'node:fs';
import path from 'node:path';

function loadEnvLocal() {
  const envPath = path.join(process.cwd(), '.env.local');
  if (!existsSync(envPath)) return;
  for (const line of readFileSync(envPath, 'utf8').split('\n')) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const eq = trimmed.indexOf('=');
    if (eq === -1) continue;
    const key = trimmed.slice(0, eq);
    const value = trimmed.slice(eq + 1);
    if (!(key in process.env)) {
      process.env[key] = value;
    }
  }
}

loadEnvLocal();

import globalSetup from './global-setup.ts';

await globalSetup();
console.log('E2E global setup complete.');
