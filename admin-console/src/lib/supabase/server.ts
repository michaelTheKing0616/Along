import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';
import type { Database } from '@along/contracts/db.types';
import type { AuditLogPage, AuditLogRow } from '@/lib/audit/types';

export type { AuditLogRow, AuditLogFilters, AuditLogPage } from '@/lib/audit/types';

export async function createClient() {
  const cookieStore = await cookies();

  return createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            );
          } catch {
            // setAll from Server Component — middleware handles refresh.
          }
        },
      },
    }
  );
}

export async function getSession() {
  const supabase = await createClient();
  const { data, error } = await supabase.auth.getSession();
  if (error) return null;
  return data.session;
}

export async function checkAdminRole(roles: readonly string[]): Promise<boolean> {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc('has_admin_role', { roles: [...roles] });
  if (error) return false;
  return Boolean(data);
}

export async function isAdmin(): Promise<boolean> {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc('is_admin');
  if (error) return false;
  return Boolean(data);
}

const DEFAULT_AUDIT_PAGE_SIZE = 50;

export async function fetchAuditLogForTarget(
  targetId: string,
  limit = 20
): Promise<AuditLogRow[]> {
  const page = await fetchAuditLogPage({ targetId, limit });
  return page.rows;
}

export async function fetchAuditLogPage(input: {
  cursor?: number;
  limit?: number;
  targetId?: string;
  action?: string;
  targetType?: string;
  actorRole?: string;
}): Promise<AuditLogPage> {
  const supabase = await createClient();
  const pageSize = Math.min(Math.max(input.limit ?? DEFAULT_AUDIT_PAGE_SIZE, 1), 200);

  let query = supabase
    .from('audit_log' as 'app_config')
    .select(
      'id, actor_id, actor_role, action, target_type, target_id, before, after, created_at'
    )
    .order('created_at', { ascending: false })
    .order('id', { ascending: false })
    .limit(pageSize + 1);

  if (input.cursor != null) {
    query = query.lt('id', input.cursor);
  }
  if (input.targetId) {
    query = query.eq('target_id', input.targetId);
  }
  if (input.action) {
    query = query.eq('action', input.action);
  }
  if (input.targetType) {
    query = query.eq('target_type', input.targetType);
  }
  if (input.actorRole) {
    query = query.eq('actor_role', input.actorRole);
  }

  const { data, error } = await query;
  if (error || !data) {
    return { rows: [], nextCursor: null, pageSize };
  }

  const rows = data as unknown as AuditLogRow[];
  const hasMore = rows.length > pageSize;
  const pageRows = hasMore ? rows.slice(0, pageSize) : rows;

  return {
    rows: pageRows,
    nextCursor: hasMore ? pageRows[pageRows.length - 1]?.id ?? null : null,
    pageSize,
  };
}
