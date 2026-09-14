import { z } from 'zod';
import { createServiceClient } from '../_shared/supabase.ts';
import { verifyStandardWebhook } from '../_shared/webhook_verify.ts';
import type { SupabaseClient } from '@supabase/supabase-js';

export const sendSmsHookSchema = z.object({
  user: z.object({
    id: z.string().uuid(),
    phone: z.string().nullable().optional(),
  }),
  sms: z.object({
    otp: z.string().min(4).max(10),
  }),
});

export type SendSmsHookPayload = z.infer<typeof sendSmsHookSchema>;

export type SendSmsDeps = {
  service: SupabaseClient;
  hookSecrets: string | undefined;
  log: (entry: Record<string, unknown>) => void;
};

function phoneSuffix(phone: string | null | undefined): string {
  if (!phone) return '????';
  const digits = phone.replace(/\D/g, '');
  return digits.slice(-4) || '????';
}

async function smsProvider(service: SupabaseClient): Promise<string> {
  const { data, error } = await service.rpc('cfg', { p_key: 'sms.provider', p_city: null });
  if (error) throw error;
  if (typeof data === 'string') return data.replace(/^"|"$/g, '');
  return String(data ?? 'log');
}

export async function handleSendSms(
  req: Request,
  deps: SendSmsDeps,
): Promise<Response> {
  const payloadText = await req.text();
  let raw: unknown;
  try {
    raw = await verifyStandardWebhook(payloadText, req.headers, deps.hookSecrets);
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Webhook verification failed';
    return new Response(JSON.stringify({ error: message }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const parsed = sendSmsHookSchema.safeParse(raw);
  if (!parsed.success) {
    return new Response(JSON.stringify({ error: parsed.error.message }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const provider = await smsProvider(deps.service);
  const phone = parsed.data.user.phone ?? null;

  if (provider === 'log') {
    // OTP stays out of stdout (ADR-0012). Staging device smokes read via peek_log_otp.
    await deps.service.rpc('record_log_otp', {
      p_phone: phone ?? '',
      p_otp: parsed.data.sms.otp,
    });
    deps.log({
      event: 'sms_otp_log',
      provider,
      user_id: parsed.data.user.id,
      phone_suffix: phoneSuffix(phone),
    });
    return new Response('{}', {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  return new Response(
    JSON.stringify({ error: `SMS provider ${provider} is not configured in staging` }),
    { status: 501, headers: { 'Content-Type': 'application/json' } },
  );
}

export function handleSendSmsDefault(req: Request): Promise<Response> {
  return handleSendSms(req, {
    service: createServiceClient(),
    hookSecrets: Deno.env.get('SEND_SMS_HOOK_SECRETS'),
    log: (entry) => console.log(JSON.stringify(entry)),
  });
}
