import { z } from 'zod';
import { jsonResponse } from '../../_shared/http.ts';
import { verifyPaystackSignature } from '../../_shared/payments/mod.ts';
import { createServiceClient } from '../../_shared/supabase.ts';
import type { SupabaseClient } from '@supabase/supabase-js';

export const paystackEventSchema = z.object({
  event: z.string(),
  data: z.object({
    reference: z.string().optional(),
    amount: z.number().optional(),
    metadata: z.record(z.unknown()).optional(),
  }).passthrough(),
});

export type PaystackWebhookDeps = {
  service: SupabaseClient;
  paystackSecret: string;
  verifySignature: typeof verifyPaystackSignature;
};

async function storeWebhookRaw(
  service: SupabaseClient,
  signatureOk: boolean,
  body: unknown,
): Promise<void> {
  const { error } = await service.schema('private').from('payment_webhook_raw').insert({
    provider: 'paystack',
    signature_ok: signatureOk,
    body: body as Record<string, unknown>,
  });
  if (error) throw new Error(error.message);
}

export async function handlePaystackWebhook(
  req: Request,
  deps: PaystackWebhookDeps,
): Promise<Response> {
  const rawBody = await req.text();
  const signature = req.headers.get('x-paystack-signature');
  let parsedBody: unknown;

  try {
    parsedBody = JSON.parse(rawBody);
  } catch {
    parsedBody = { parse_error: true, raw: rawBody };
  }

  const signatureOk = await deps.verifySignature(rawBody, signature, deps.paystackSecret);
  await storeWebhookRaw(deps.service, signatureOk, parsedBody);

  if (!signatureOk) {
    return new Response(JSON.stringify({ error: 'Invalid signature' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const parsed = paystackEventSchema.safeParse(parsedBody);
  if (parsed.success) {
    const reference = parsed.data.data.reference;
    const amountKobo = parsed.data.data.amount ?? 0;
    const metadata = parsed.data.data.metadata ?? {};

    if (reference && parsed.data.event === 'charge.success') {
      const { error } = await deps.service.rpc('apply_paystack_charge_success', {
        p_reference: reference,
        p_amount: amountKobo / 100,
        p_metadata: metadata,
      });
      if (error) {
        console.error(JSON.stringify({ event: 'paystack_webhook_ledger_error', message: error.message }));
      }
    }

    if (reference && parsed.data.event === 'transfer.success') {
      const { error } = await deps.service.rpc('apply_paystack_transfer_success', {
        p_reference: reference,
        p_amount: amountKobo / 100,
        p_metadata: metadata,
      });
      if (error) {
        console.error(JSON.stringify({ event: 'paystack_transfer_webhook_error', message: error.message }));
      }
    }
  }

  return jsonResponse({ received: true });
}

export function handlePaystackWebhookDefault(req: Request): Promise<Response> {
  const secret = Deno.env.get('PAYSTACK_SECRET_KEY');
  if (!secret) {
    throw new Error('PAYSTACK_SECRET_KEY not configured');
  }
  return handlePaystackWebhook(req, {
    service: createServiceClient(),
    paystackSecret: secret,
    verifySignature: verifyPaystackSignature,
  });
}
