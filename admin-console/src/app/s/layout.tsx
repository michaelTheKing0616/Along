import type { ReactNode } from 'react';
import './share.css';

export default function SharedTripLayout({ children }: { children: ReactNode }) {
  return (
    <div className="w01-shell" data-testid="w01-shell">
      {children}
    </div>
  );
}
