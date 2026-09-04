import Link from 'next/link';
import { AuditDrawer } from '@/components/along/AuditDrawer';

interface PageProps {
  params: Promise<{ city: string }>;
}

export default async function DashboardPage({ params }: PageProps) {
  const { city } = await params;

  return (
    <>
      <div className="page-header">
        <h1>Dashboard</h1>
        <p>
          City: <strong>{city}</strong>
        </p>
      </div>
      <nav className="nav-links" aria-label="Console navigation">
        <Link href={`/${city}/dashboard`}>Dashboard</Link>
        <Link href={`/${city}/verification`}>Verification</Link>
        <Link href={`/${city}/finance`}>Finance</Link>
        <Link href={`/${city}/safety`}>Safety</Link>
        <Link href={`/${city}/audit`}>Audit</Link>
        <Link href={`/${city}/admins`}>Admins</Link>
      </nav>
      <AuditDrawer targetId="commission.rate" targetLabel="Global commission config" />
    </>
  );
}
