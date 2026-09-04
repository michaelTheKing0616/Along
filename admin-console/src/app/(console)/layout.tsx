import Link from 'next/link';
import type { ReactNode } from 'react';

export default function ConsoleLayout({ children }: { children: ReactNode }) {
  return (
    <div className="page-shell">
      <header className="page-header">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <strong>Along Admin</strong>
          <Link href="/sign-in" style={{ fontSize: '0.875rem' }}>
            Sign out
          </Link>
        </div>
      </header>
      {children}
    </div>
  );
}
