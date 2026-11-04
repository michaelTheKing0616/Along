import Link from "next/link";
import type { ReactNode } from "react";
import { AlongLogo } from "@/components/along/along-logo";

export default function AgentLayout({ children }: { children: ReactNode }) {
  return (
    <div className="page-shell agent-shell">
      <header className="page-header agent-header">
        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
          }}
        >
          <strong className="agent-brand">
            <AlongLogo width={84} className="brand-logo" />
            Agent
          </strong>
          <Link
            href="/sign-in"
            style={{ fontSize: "0.875rem", color: "var(--color-ink-900)" }}
          >
            Sign out
          </Link>
        </div>
      </header>
      {children}
    </div>
  );
}
