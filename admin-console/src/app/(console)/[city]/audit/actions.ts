'use server';

import { revalidatePath } from 'next/cache';
import type { AuditLogPage } from '@/lib/audit/types';
import { fetchAuditLogPage } from '@/lib/supabase/server';

export async function loadAuditPage(input: {
  citySlug: string;
  cursor?: number;
  action?: string;
  targetType?: string;
  actorRole?: string;
  targetId?: string;
}): Promise<{ ok: true; page: AuditLogPage } | { ok: false; error: string }> {
  try {
    const page = await fetchAuditLogPage({
      cursor: input.cursor,
      action: input.action || undefined,
      targetType: input.targetType || undefined,
      actorRole: input.actorRole || undefined,
      targetId: input.targetId || undefined,
    });
    return { ok: true, page };
  } catch (err) {
    return { ok: false, error: err instanceof Error ? err.message : 'Failed to load audit log' };
  }
}

export async function refreshAuditPath(citySlug: string) {
  revalidatePath(`/${citySlug}/audit`);
}
