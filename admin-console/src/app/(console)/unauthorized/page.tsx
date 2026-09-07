import Link from 'next/link';
import { createClient } from '@/lib/supabase/server';

export default async function UnauthorizedPage() {
  const supabase = await createClient();
  const { data } = await supabase
    .from('cities')
    .select('slug')
    .in('status', ['alpha', 'beta', 'live'])
    .order('name')
    .limit(1)
    .maybeSingle();

  const dashboardHref = `/${data?.slug ?? 'abuja'}/dashboard`;

  return (
    <main className="page-center">
      <div className="card" style={{ maxWidth: '28rem', textAlign: 'center' }}>
        <h1 style={{ marginTop: 0 }}>Unauthorized</h1>
        <p style={{ color: 'var(--color-text-muted)' }}>
          Your role does not have access to this page.
        </p>
        <Link href={dashboardHref}>Return to dashboard</Link>
      </div>
    </main>
  );
}
