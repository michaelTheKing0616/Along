import Link from 'next/link';

interface ConsoleNavProps {
  city: string;
}

const LINKS = [
  { segment: 'dashboard', label: 'Dashboard' },
  { segment: 'field', label: 'Field reconciliation' },
  { segment: 'graph', label: 'Graph editor' },
  { segment: 'deploy', label: 'City playbook' },
  { segment: 'verification', label: 'Verification' },
  { segment: 'finance', label: 'Finance' },
  { segment: 'safety', label: 'Safety' },
  { segment: 'audit', label: 'Audit' },
  { segment: 'admins', label: 'Admins' },
] as const;

export function ConsoleNav({ city }: ConsoleNavProps) {
  return (
    <nav className="nav-links" aria-label="Console navigation">
      {LINKS.map(({ segment, label }) => (
        <Link key={segment} href={`/${city}/${segment}`}>
          {label}
        </Link>
      ))}
    </nav>
  );
}
