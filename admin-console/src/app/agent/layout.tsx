import Link from "next/link";
import type { ReactNode } from "react";

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
            <span className="brand-plate">
              <img
                src="/brand/along-logo.svg"
                alt="Along"
                width={78}
                height={20}
              />
            </span>
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
