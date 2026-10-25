import { assertEquals } from 'jsr:@std/assert@1';
import type { SupabaseClient } from '@supabase/supabase-js';
import {
  handleStagingOtp,
  KEY_HEADER,
  looksLikeProduction,
  RateLimiter,
  safeEqual,
  type StagingOtpEnv,
} from './handler.ts';

const KEY = 'k'.repeat(40);
const PHONE = '+2348000000001';
const OTP = '482913';

const ENV: StagingOtpEnv = {
  ALONG_ENV: 'staging',
  STAGING_OTP_KEY: KEY,
  STAGING_OTP_ALLOWLIST: `${PHONE}, +2348000000002`,
  ALONG_PROD_PROJECT_REFS: 'prodref123',
  SUPABASE_URL: 'https://stagingref456.supabase.co',
};

function harness(env: Partial<StagingOtpEnv> = {}, provider: string | null = 'log') {
  const logs: Record<string, unknown>[] = [];
  const rpcs: string[] = [];
  const service = {
    rpc: (name: string) => {
      rpcs.push(name);
      if (name === 'cfg') {
        return Promise.resolve({
          data: provider === null ? null : JSON.stringify(provider),
          error: null,
        });
      }
      if (name === 'peek_log_otp') return Promise.resolve({ data: OTP, error: null });
      return Promise.resolve({ data: null, error: { message: name } });
    },
  } as unknown as SupabaseClient;
  const deps = {
    env: { ...ENV, ...env },
    service: () => service,
    log: (e: Record<string, unknown>) => logs.push(e),
    rateLimiter: new RateLimiter(3, 60_000),
    now: () => 1_000,
  };
  const call = (opts: { key?: string | null; phone?: unknown; method?: string } = {}) => {
    const headers = new Headers({
      'Content-Type': 'application/json',
      'x-forwarded-for': '10.0.0.1',
    });
    const key = opts.key === undefined ? KEY : opts.key;
    if (key !== null) headers.set(KEY_HEADER, key);
    const method = opts.method ?? 'POST';
    return handleStagingOtp(
      new Request('http://x/staging-otp', {
        method,
        headers,
        body: method === 'POST' ? JSON.stringify({ phone: opts.phone ?? PHONE }) : undefined,
      }),
      deps,
    );
  };
  return { call, logs, rpcs };
}

function assertNoOtpLogged(logs: Record<string, unknown>[]) {
  assertEquals(JSON.stringify(logs).includes(OTP), false);
}

Deno.test('staging-otp: allow path returns the OTP and never logs it', async () => {
  const h = harness();
  const res = await h.call();
  assertEquals(res.status, 200);
  assertEquals(await res.json(), { otp: OTP });
  assertEquals(h.logs.at(-1)?.event, 'staging_otp_served');
  assertNoOtpLogged(h.logs);
});

for (
  const [name, env] of [
    ['ALONG_ENV unset', { ALONG_ENV: undefined }],
    ['ALONG_ENV=production', { ALONG_ENV: 'production' }],
    ['prod project ref in SUPABASE_URL', { SUPABASE_URL: 'https://prodref123.supabase.co' }],
    ['prod-looking host', { SUPABASE_URL: 'https://along-prod.example.com' }],
    ['unparseable SUPABASE_URL', { SUPABASE_URL: 'not a url' }],
    ['server key unset', { STAGING_OTP_KEY: undefined }],
    ['server key too short', { STAGING_OTP_KEY: 'short' }],
  ] as const
) {
  Deno.test(`staging-otp: 404 when ${name}`, async () => {
    const h = harness(env as Partial<StagingOtpEnv>);
    const res = await h.call();
    assertEquals(res.status, 404);
    assertEquals(h.rpcs, []);
    assertEquals(h.logs[0]?.event, 'staging_otp_denied');
  });
}

Deno.test('staging-otp: 404 when key header absent', async () => {
  const h = harness();
  assertEquals((await h.call({ key: null })).status, 404);
  assertEquals(h.rpcs, []);
});

Deno.test('staging-otp: 403 on key mismatch', async () => {
  const h = harness();
  const res = await h.call({ key: `${KEY}x` });
  assertEquals(res.status, 403);
  assertEquals(h.logs[0]?.reason, 'key_mismatch');
  assertEquals(h.rpcs, []);
});

Deno.test('staging-otp: 403 for a number off the allowlist', async () => {
  const h = harness();
  const res = await h.call({ phone: '+2348099999999' });
  assertEquals(res.status, 403);
  assertEquals(h.logs[0]?.reason, 'phone_not_allowlisted');
  assertEquals(h.rpcs, []);
});

Deno.test('staging-otp: empty allowlist denies everything', async () => {
  for (const allow of [undefined, '', ' , ']) {
    const h = harness({ STAGING_OTP_ALLOWLIST: allow });
    assertEquals((await h.call()).status, 403);
    assertEquals(h.rpcs, []);
  }
});

Deno.test('staging-otp: 403 when sms.provider is not log (or unset)', async () => {
  for (const provider of ['termii', null]) {
    const h = harness({}, provider);
    const res = await h.call();
    assertEquals(res.status, 403);
    assertEquals(h.rpcs.includes('peek_log_otp'), false);
  }
});

Deno.test('staging-otp: rejects malformed phone and non-POST', async () => {
  assertEquals((await harness().call({ phone: '0800' })).status, 400);
  assertEquals((await harness().call({ method: 'GET' })).status, 405);
});

Deno.test('staging-otp: rate-limits repeated calls', async () => {
  const h = harness();
  for (let i = 0; i < 3; i++) assertEquals((await h.call()).status, 200);
  const res = await h.call();
  assertEquals(res.status, 429);
  assertEquals(h.logs.at(-1)?.reason, 'rate_limited');
  assertNoOtpLogged(h.logs);
});

Deno.test('staging-otp: helpers', async () => {
  assertEquals(await safeEqual('abc', 'abc'), true);
  assertEquals(await safeEqual('abc', 'abd'), false);
  assertEquals(await safeEqual('abc', 'abcd'), false);
  assertEquals(looksLikeProduction(ENV), false);
});
