'use server';

import { revalidatePath } from 'next/cache';
import type { CountryFormInput, VerificationDocRow } from '@/lib/markets/types';
import {
  buildCountrySchemaPayload,
  buildCountryUpsertPayload,
} from '@/lib/markets/payload';
import { createClient } from '@/lib/supabase/server';
import { rpcUntyped } from '@/lib/supabase/untyped';

export type MarketsActionResult =
  | { ok: true; message: string; payload?: Record<string, unknown> }
  | { ok: false; error: string; code?: string };

function rpcError(error: { message: string; code?: string }): MarketsActionResult {
  return { ok: false, error: error.message, code: error.code };
}

export async function upsertCountry(
  citySlug: string,
  input: CountryFormInput
): Promise<MarketsActionResult> {
  const supabase = await createClient();
  const payload = buildCountryUpsertPayload(input);
  const { data, error } = await rpcUntyped(supabase, 'admin_upsert_country', payload);

  if (error) return rpcError(error);

  const schemaPayload = buildCountrySchemaPayload(input.code, input.verification_schema);
  const { error: schemaError } = await rpcUntyped(
    supabase,
    'admin_set_country_schema',
    schemaPayload
  );

  if (schemaError) return rpcError(schemaError);

  revalidatePath(`/${citySlug}/markets`);

  const result = (data ?? {}) as Record<string, unknown>;
  return {
    ok: true,
    message: `Country ${String(result.code ?? input.code)} saved (config-only — no app code changes).`,
    payload: result,
  };
}

export async function setCountrySchema(
  citySlug: string,
  code: string,
  schema: VerificationDocRow[]
): Promise<MarketsActionResult> {
  const supabase = await createClient();
  const payload = buildCountrySchemaPayload(code, schema);
  const { data, error } = await rpcUntyped(supabase, 'admin_set_country_schema', payload);

  if (error) return rpcError(error);

  revalidatePath(`/${citySlug}/markets`);

  const result = (data ?? {}) as Record<string, unknown>;
  return {
    ok: true,
    message: `Verification schema updated for ${String(result.code ?? code)}.`,
    payload: result,
  };
}

export async function updateCountryFlags(
  citySlug: string,
  input: CountryFormInput
): Promise<MarketsActionResult> {
  return upsertCountry(citySlug, input);
}

export async function updatePaymentProvider(
  citySlug: string,
  input: CountryFormInput
): Promise<MarketsActionResult> {
  return upsertCountry(citySlug, input);
}
