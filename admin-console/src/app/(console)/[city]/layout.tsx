import Link from 'next/link';
import type { ReactNode } from 'react';
import { ConsoleNav } from '@/components/along/ConsoleNav';
import { RowKeyboard } from '@/components/along/RowKeyboard';
import { getCityBySlug } from '@/lib/city/resolve';
import { createClient } from '@/lib/supabase/server';

interface LayoutProps {
  children: ReactNode;
  params: Promise<{ city: string }>;
}

export default async function CityShellLayout({ children, params }: LayoutProps) {
  const { city: citySlug } = await params;
  const [city, user] = await Promise.all([
    getCityBySlug(citySlug),
    createClient()
      .then((s) => s.auth.getUser())
      .then(({ data }) => data.user),
  ]);

  return (
    <div className="shell">
      <a href="#main" className="skip-link">
        Skip to content
      </a>
      <aside className="shell-side">
        <div>
          <Link href={`/${citySlug}/dashboard`} className="shell-brand">
            <span className="shell-mark" aria-hidden="true">
              A
            </span>
            Along Admin
          </Link>
          <div className="shell-city">{city?.name ?? citySlug}</div>
        </div>
        <ConsoleNav city={citySlug} />
        <div className="shell-foot">
          <span className="shell-user">{user?.email ?? ''}</span>
          <Link href="/sign-in">Sign out</Link>
        </div>
      </aside>
      <main id="main" className="shell-main" tabIndex={-1}>
        <div className="shell-content">{children}</div>
        <RowKeyboard />
      </main>
    </div>
  );
}
