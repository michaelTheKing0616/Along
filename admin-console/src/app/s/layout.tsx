import type { ReactNode } from 'react';
import './share.css';

export default function SharedTripLayout({ children }: { children: ReactNode }) {
  return (
    <>
      <style>{`:root { --w01-ink: #0A0A0A; --w01-yellow: #F7D117; }`}</style>
      <div className="w01-shell" data-testid="w01-shell">
        {children}
      </div>
    </>
  );
}
