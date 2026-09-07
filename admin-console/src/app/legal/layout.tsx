import type { ReactNode } from 'react';
import type { Metadata } from 'next';
import './legal.css';

export const metadata: Metadata = {
  title: 'Legal · Along',
  description: 'Along terms of service and privacy notice',
};

export default function LegalLayout({ children }: { children: ReactNode }) {
  return (
    <div className="w03-shell" data-testid="w03-shell">
      {children}
    </div>
  );
}
