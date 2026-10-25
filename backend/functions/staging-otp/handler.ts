// staging-otp: lets staging device smokes auto-fill the log-mode OTP.
// Every guard fails closed. Production must never deploy this function
// (scripts/deploy_functions.sh excludes it); if it is deployed anyway, guard 1/2
// make it answer 404 like a missing route.
import type { SupabaseClient } from '@supabase/supabase-js';
import { createServiceClient } from '../_shared/supabase.ts';

export const KEY_HEADER = 'x-staging-otp-key';
const MIN_KEY_LENGTH = 32;
const E164 = /^\+[1-9]\d{7,14}$/;

export interface StagingOtpEnv {
  ALONG_ENV?: string;
  STAGING_OTP_KEY?: string;
  /** Comma-separated E.164 test numbers. Empty or unset => deny all. */
  STAGING_OTP_ALLOWLIST?: string;
  /** Comma-separated production project refs or hosts; a match => deny. */
  ALONG_PROD_PROJECT_REFS?: string;
  SUPABASE_URL?: string;
}

export interface StagingOtpDeps {
  env: StagingOtpEnv;
  service: () => SupabaseClient;
  log: (entry: Record<string, unknown>) => void;
  rateLimiter?: RateLimiter;
  now?: () => number;
}

export class RateLimiter {
  private hits = new Map<string, number[]>();
  constructor(private limit = 10, private windowMs = 60_000) {}
  allow(key: string, now: number): boolean {
    const recent = (this.hits.get(key) ?? []).filter((t) => now - t < this.windowMs);
    if (recent.length >= this.limit) {
      this.hits.set(key, recent);
      return false;
    }
    recent.push(now);
    this.hits.set(key, recent);
    return true;
  }
}

const defaultLimiter = new RateLimiter();

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' },
  });
}

const notFound = () => json(404, { error: 'not_found' });

function phoneSuffix(phone: string | null): string {
  const digits = (phone ?? '').replace(/\D/g, '');
  return digits.slice(-4) || '????';
}

/** Constant-time comparison over SHA-256 digests (length-independent). */
export async function safeEqual(a: string, b: string): Promise<boolean> {
  const enc = new TextEncoder();
  const [da, db] = await Promise.all([
    crypto.subtle.digest('SHA-256', enc.encode(a)),
    crypto.subtle.digest('SHA-256', enc.encode(b)),
  ]);
  const x = new Uint8Array(da);
  const y = new Uint8Array(db);
  let diff = 0;
  for (let i = 0; i < x.length; i++) diff |= x[i] ^ y[i];
  return diff === 0;
}

function list(raw: string | undefined): string[] {
  return (raw ?? '').split(',').map((s) => s.trim()).filter(Boolean);
}

/** True when anything about the runtime points at production. */
export function looksLikeProduction(env: StagingOtpEnv): boolean {
  if (env.ALONG_ENV !== 'staging') return true;
  let host = '';
  try {
    host = new URL(env.SUPABASE_URL ?? '').hostname.toLowerCase();
  } catch {
    return true;
  }
  if (!host || /(^|[.-])prod(uction)?([.-]|$)/.test(host)) return true;
  return list(env.ALONG_PROD_PROJECT_REFS).some((ref) => {
    const r = ref.toLowerCase();
    return host === r || host.startsWith(`${r}.`) ||
      (env.SUPABASE_URL ?? '').toLowerCase().includes(r);
  });
}

async function smsProvider(service: SupabaseClient): Promise<string | null> {
  const { data, error } = await service.rpc('cfg', { p_key: 'sms.provider', p_city: null });
  if (error || data == null) return null;
  return typeof data === 'string' ? data.replace(/^"|"$/g, '') : String(data);
}

export async function handleStagingOtp(req: Request, deps: StagingOtpDeps): Promise<Response> {
  const { env, log } = deps;
  const deny = (status: number, reason: string, phone: string | null = null) => {
    log({ event: 'staging_otp_denied', reason, phone_suffix: phoneSuffix(phone) });
    return status === 404 ? notFound() : json(status, { error: reason });
  };

  // (1) + (4): only exists on staging, never on anything production-looking.
  if (env.ALONG_ENV !== 'staging') return deny(404, 'not_staging');
  if (looksLikeProduction(env)) return deny(404, 'production_environment');

  // (2) Secret key: unset/weak server key or absent header => 404; mismatch => 403.
  const serverKey = env.STAGING_OTP_KEY ?? '';
  if (serverKey.length < MIN_KEY_LENGTH) return deny(404, 'key_not_configured');
  const presented = req.headers.get(KEY_HEADER);
  if (!presented) return deny(404, 'key_missing');
  if (!(await safeEqual(presented, serverKey))) return deny(403, 'key_mismatch');

  if (req.method !== 'POST') return deny(405, 'method_not_allowed');

  let phone: string | null = null;
  try {
    const body = await req.json();
    phone = typeof body?.phone === 'string' ? body.phone.trim() : null;
  } catch {
    return deny(400, 'invalid_body');
  }
  if (!phone || !E164.test(phone)) return deny(400, 'invalid_phone', phone);

  const ip = req.headers.get('x-forwarded-for')?.split(',')[0]?.trim() ?? 'unknown';
  const limiter = deps.rateLimiter ?? defaultLimiter;
  if (!limiter.allow(`${ip}|${phone}`, (deps.now ?? Date.now)())) {
    return deny(429, 'rate_limited', phone);
  }

  // (3) Allowlisted test numbers only; empty allowlist denies everything.
  if (!list(env.STAGING_OTP_ALLOWLIST).includes(phone)) {
    return deny(403, 'phone_not_allowlisted', phone);
  }

  // (4) sms.provider must be log mode.
  const service = deps.service();
  if ((await smsProvider(service)) !== 'log') return deny(403, 'sms_provider_not_log', phone);

  const { data, error } = await service.rpc('peek_log_otp', { p_phone: phone });
  if (error) {
    log({ event: 'staging_otp_error', phone_suffix: phoneSuffix(phone) });
    return json(500, { error: 'peek_failed' });
  }
  const otp = typeof data === 'string' && data.length > 0 ? data : null;
  // Never log the OTP value itself.
  log({ event: 'staging_otp_served', found: otp !== null, phone_suffix: phoneSuffix(phone) });
  return json(200, { otp });
}

export function handleStagingOtpDefault(req: Request): Promise<Response> {
  return handleStagingOtp(req, {
    env: {
      ALONG_ENV: Deno.env.get('ALONG_ENV'),
      STAGING_OTP_KEY: Deno.env.get('STAGING_OTP_KEY'),
      STAGING_OTP_ALLOWLIST: Deno.env.get('STAGING_OTP_ALLOWLIST'),
      ALONG_PROD_PROJECT_REFS: Deno.env.get('ALONG_PROD_PROJECT_REFS'),
      SUPABASE_URL: Deno.env.get('SUPABASE_URL'),
    },
    service: createServiceClient,
    log: (entry) => console.log(JSON.stringify(entry)),
  });
}
