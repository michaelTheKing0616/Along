import type { AdminUserRow } from '@/lib/admins/types';
import { createClient } from '@/lib/supabase/server';
import { AdminsConsole } from './admins-console';

interface PageProps {
  params: Promise<{ city: string }>;
}

async function loadInitialAdmins(): Promise<{
  rows: AdminUserRow[];
  nextCursor: string | null;
}> {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc('admin_list_admins', {});

  if (error || !data) {
    return { rows: [], nextCursor: null };
  }

  const payload = data as { rows?: AdminUserRow[]; next_cursor?: string | null };
  return {
    rows: payload.rows ?? [],
    nextCursor: payload.next_cursor ?? null,
  };
}

async function loadDeployments() {
  const supabase = await createClient();
  const { data } = await supabase.from('deployments').select('id, tenant_name').order('tenant_name');
  return (data ?? []).map((row) => ({ id: row.id, tenant_name: row.tenant_name }));
}

async function loadCities() {
  const supabase = await createClient();
  const { data } = await supabase.from('cities').select('id, name, slug').order('name');
  return (data ?? []).map((row) => ({ id: row.id, name: row.name, slug: row.slug }));
}

export default async function AdminsPage({ params }: PageProps) {
  const { city } = await params;
  const [{ rows, nextCursor }, deployments, cities] = await Promise.all([
    loadInitialAdmins(),
    loadDeployments(),
    loadCities(),
  ]);

  return (
    <>
      <div className="page-header">
        <h1>Admin users</h1>
        <p>
          Invite admins, set roles and city scope, disable accounts, and check two-factor enrolment.
        </p>
      </div>
      <AdminsConsole
        citySlug={city}
        initialRows={rows}
        initialNextCursor={nextCursor}
        deployments={deployments}
        cities={cities}
      />
    </>
  );
}
