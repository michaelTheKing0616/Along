import { mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { createClient } from '@supabase/supabase-js';
import { authenticator } from 'otplib';

const SUPABASE_URL = process.env.SUPABASE_URL ?? 'http://127.0.0.1:54321';
const SERVICE_ROLE_KEY =
  process.env.SUPABASE_SERVICE_ROLE_KEY ??
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU';
const ANON_KEY =
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ??
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';

export const E2E_PASSWORD = 'AlongE2E2026!';
export const E2E_CITY = 'abuja';

export const TEST_USERS = [
  { email: 'e2e-superadmin@along.local', role: 'superadmin', requiresMfa: true },
  { email: 'e2e-finance@along.local', role: 'finance', requiresMfa: true },
  { email: 'e2e-finance2@along.local', role: 'finance', requiresMfa: true },
  { email: 'e2e-verifier@along.local', role: 'verifier', requiresMfa: false },
  { email: 'e2e-analyst@along.local', role: 'analyst', requiresMfa: false },
  { email: 'e2e-ops-agent@along.local', role: 'ops_agent', requiresMfa: false },
  { email: 'e2e-safety@along.local', role: 'safety', requiresMfa: false },
] as const;

export interface TotpSecrets {
  [email: string]: string;
}

async function enrollTotp(email: string, password: string): Promise<string> {
  const client = createClient(SUPABASE_URL, ANON_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { error: signInError } = await client.auth.signInWithPassword({ email, password });
  if (signInError) {
    throw new Error(`Sign-in failed during MFA enroll for ${email}: ${signInError.message}`);
  }

  const { data: factors } = await client.auth.mfa.listFactors();
  const verified = factors?.totp.find((f) => f.status === 'verified');
  if (verified) {
    throw new Error(
      `TOTP already enrolled for ${email}; run db reset or seed-e2e-admins.sql to clear factors.`
    );
  }
  for (const factor of factors?.totp ?? []) {
    if (factor.status !== 'verified') {
      await client.auth.mfa.unenroll({ factorId: factor.id });
    }
  }

  const { data: enrolled, error: enrollError } = await client.auth.mfa.enroll({
    factorType: 'totp',
    friendlyName: `E2E-${email.split('@')[0]}`,
  });
  if (enrollError || !enrolled?.totp?.secret) {
    throw new Error(`MFA enroll failed for ${email}: ${enrollError?.message ?? 'no secret'}`);
  }

  const secret = enrolled.totp.secret;
  const code = authenticator.generate(secret);

  const { data: challenge, error: challengeError } = await client.auth.mfa.challenge({
    factorId: enrolled.id,
  });
  if (challengeError || !challenge) {
    throw new Error(`MFA challenge failed for ${email}: ${challengeError?.message}`);
  }

  const { error: verifyError } = await client.auth.mfa.verify({
    factorId: enrolled.id,
    challengeId: challenge.id,
    code,
  });
  if (verifyError) {
    throw new Error(`MFA verify failed for ${email}: ${verifyError.message}`);
  }

  await client.auth.signOut();
  return secret;
}

async function globalSetup() {
  const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const totpSecrets: TotpSecrets = {};

  for (const spec of TEST_USERS) {
    if (!spec.requiresMfa) continue;
    const { data } = await admin.auth.admin.listUsers();
    const user = data.users.find((u) => u.email === spec.email);
    if (!user) {
      throw new Error(`E2E user missing: ${spec.email}; run seed-e2e-admins.sql first.`);
    }
    totpSecrets[spec.email] = await enrollTotp(spec.email, E2E_PASSWORD);
  }

  const authDir = path.join(process.cwd(), 'e2e', '.auth');
  await mkdir(authDir, { recursive: true });
  await writeFile(path.join(authDir, 'totp-secrets.json'), JSON.stringify(totpSecrets, null, 2));
}

export default globalSetup;
