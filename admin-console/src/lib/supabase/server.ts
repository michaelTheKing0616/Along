import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';
import type { Database } from '@along/contracts/db.types';

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

export type AuditLogRow = {
  id: number;
  actor_id: string | null;
  actor_role: string | null;
  action: string;
  target_type: string;
  target_id: string;
  created_at: string;
};

export async function fetchAuditLogForTarget(
  targetId: string,
  limit = 20
): Promise<AuditLogRow[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from('audit_log' as 'app_config')
    .select('id, actor_id, actor_role, action, target_type, target_id, created_at')
    .eq('target_id', targetId)
    .order('created_at', { ascending: false })
    .limit(limit);

  if (error || !data) return [];
  return data as unknown as AuditLogRow[];
}
