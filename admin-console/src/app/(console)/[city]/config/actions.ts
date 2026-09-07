'use server';

import type { Json } from '@along/contracts/db.types';
import { revalidatePath } from 'next/cache';
import { createClient } from '@/lib/supabase/server';
import type { ConfigScope } from '@/lib/config/keys';

export type ConfigActionResult =
  | { ok: true; message: string }
  | { ok: false; error: string };

export async function setConfigValue(input: {
  citySlug: string;
  key: string;
  scopeType: ConfigScope;
  scopeId: string;
  value: unknown;
  reason: string;
}): Promise<ConfigActionResult> {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc('admin_set_config', {
    p_key: input.key,
    p_scope_type: input.scopeType,
    p_scope_id: input.scopeId,
    p_value: input.value as Json,
    p_reason: input.reason,
  });

  if (error) return { ok: false, error: error.message };

  revalidatePath(`/${input.citySlug}/config`);
  return {
    ok: true,
    message: `Saved ${input.key} at ${input.scopeType} scope (audit #${JSON.stringify(data)})`,
  };
}
