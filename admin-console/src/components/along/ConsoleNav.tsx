'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';

interface ConsoleNavProps {
  city: string;
}

/** Grouped by job so an operator scans by intent, not alphabet. */
export const NAV_GROUPS = [
  {
    label: 'Operate',
    links: [
      { segment: 'dashboard', label: 'Dashboard' },
      { segment: 'live', label: 'Live map' },
      { segment: 'safety', label: 'Safety' },
      { segment: 'verification', label: 'Verification' },
      { segment: 'integrity', label: 'Integrity' },
      { segment: 'corrections', label: 'Fare corrections' },
      { segment: 'field', label: 'Field reconciliation' },
    ],
  },
  {
    label: 'Network',
    links: [
      { segment: 'graph', label: 'Graph editor' },
      { segment: 'intelligence', label: 'Intelligence' },
      { segment: 'deploy', label: 'City playbook' },
      { segment: 'markets', label: 'Markets' },
      { segment: 'config', label: 'Config' },
    ],
  },
  {
    label: 'Money',
    links: [
      { segment: 'finance', label: 'Finance' },
      { segment: 'revenue', label: 'Revenue' },
      { segment: 'corporate', label: 'Corporate' },
      { segment: 'operator', label: 'Operator' },
    ],
  },
  {
    label: 'Insight',
    links: [
      { segment: 'analytics', label: 'Analytics' },
      { segment: 'audit', label: 'Audit' },
      { segment: 'admins', label: 'Admins' },
    ],
  },
] as const;

export function ConsoleNav({ city }: ConsoleNavProps) {
  const pathname = usePathname() ?? '';
  const active = pathname.split('/')[2] ?? '';
  return (
    <nav className="nav-groups" aria-label="Console navigation">
      {NAV_GROUPS.map((group) => (
        <div key={group.label} className="nav-group" role="group" aria-label={group.label}>
          <span className="nav-group-label">{group.label}</span>
          {group.links.map(({ segment, label }) => (
            <Link
              key={segment}
              href={`/${city}/${segment}`}
              className="nav-item"
              aria-current={active === segment ? 'page' : undefined}
            >
              {label}
            </Link>
          ))}
        </div>
      ))}
    </nav>
  );
}
