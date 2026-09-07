import type { ReactNode } from 'react';
import './pay.css';

export default function PayLayout({ children }: { children: ReactNode }) {
  return (
    <>
      <style>{`:root { --w04-ink: #0A0A0A; --w04-yellow: #F7D117; }`}</style>
      <div className="w04-shell" data-testid="w04-shell">
        {children}
      </div>
    </>
  );
}
