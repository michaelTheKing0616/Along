import Link from 'next/link';
import type { ReactNode } from 'react';

interface LegalChromeProps {
  title: string;
  current: 'terms' | 'privacy';
  children: ReactNode;
}

export function LegalChrome({ title, current, children }: LegalChromeProps) {
  return (
    <main className="w03-main" data-testid={`w03-${current}`}>
      <p className="w03-brand">Along · Legal</p>
      <p className="w03-draft" data-testid="w03-draft-notice">
        Product draft — not counsel-approved. Final legal review is pending (P4-E-02 / P8-E-01).
      </p>
      <h1 className="w03-title">{title}</h1>
      <p className="w03-updated">Last updated: 7 September 2026</p>

      <nav className="w03-nav" aria-label="Legal documents">
        <Link href="/legal/terms" aria-current={current === 'terms' ? 'page' : undefined}>
          Terms of Service
        </Link>
        <Link href="/legal/privacy" aria-current={current === 'privacy' ? 'page' : undefined}>
          Privacy Notice
        </Link>
      </nav>

      {children}

      <footer className="w03-footer">
        Questions? Email privacy@along.ng (placeholder — wire before store submission).
      </footer>
    </main>
  );
}
