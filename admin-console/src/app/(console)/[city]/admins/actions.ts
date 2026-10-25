'use server';

import type { Database } from '@along/contracts/db.types';
import { revalidatePath } from 'next/cache';
import { createClient } from '@/lib/supabase/server';

type AdminRole = Database['public']['Enums']['admin_role'];

export type AdminActionResult =
  | { ok: true; message: string; temporaryPassword?: string }
  | { ok: false; error: string };

export async function inviteAdmin(input: {
  citySlug: string;
  email: string;
  role: AdminRole;
  deploymentId: string | null;
  cityScope: string[];
  displayName: string;
}): Promise<AdminActionResult> {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc('admin_invite_admin', {
    p_email: input.email,
    p_role: input.role,
    p_deployment_id: input.deploymentId ?? undefined, // omitted arg = SQL default null
    p_city_scope: input.cityScope.length > 0 ? input.cityScope : undefined,
    p_display_name: input.displayName || undefined,
  });

  if (error) return { ok: false, error: error.message };

  const payload = data as {
    temporary_password?: string;
    email?: string;
  } | null;

  revalidatePath(`/${input.citySlug}/admins`);
  return {
    ok: true,
    message: `Invited ${payload?.email ?? input.email}`,
    temporaryPassword: payload?.temporary_password,
  };
}

export async function updateAdmin(input: {
  citySlug: string;
  userId: string;
  role: AdminRole;
  deploymentId: string | null;
  cityScope: string[];
}): Promise<AdminActionResult> {
  const supabase = await createClient();
  const { error } = await supabase.rpc('admin_update_admin', {
    p_user_id: input.userId,
    p_role: input.role,
    p_deployment_id: input.deploymentId ?? undefined, // omitted arg = SQL default null
    p_city_scope: input.cityScope.length > 0 ? input.cityScope : undefined,
    p_clear_city_scope: input.cityScope.length === 0,
  });

  if (error) return { ok: false, error: error.message };

  revalidatePath(`/${input.citySlug}/admins`);
  return { ok: true, message: 'Admin updated.' };
}

export async function disableAdmin(input: {
  citySlug: string;
  userId: string;
}): Promise<AdminActionResult> {
  const supabase = await createClient();
  const { error } = await supabase.rpc('admin_disable_admin', {
    p_user_id: input.userId,
  });

  if (error) return { ok: false, error: error.message };

  revalidatePath(`/${input.citySlug}/admins`);
  return { ok: true, message: 'Admin disabled.' };
}

export async function loadAdminPage(input: {
  cursor?: string;
}): Promise<
  | { ok: true; rows: import('@/lib/admins/types').AdminUserRow[]; nextCursor: string | null }
  | { ok: false; error: string }
> {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc('admin_list_admins', {
    p_cursor: input.cursor ?? undefined,
  });

  if (error) return { ok: false, error: error.message };

  const payload = data as {
    rows?: import('@/lib/admins/types').AdminUserRow[];
    next_cursor?: string | null;
  } | null;

  return {
    ok: true,
    rows: payload?.rows ?? [],
    nextCursor: payload?.next_cursor ?? null,
  };
}
