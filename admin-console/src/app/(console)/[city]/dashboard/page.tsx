import { ConsoleNav } from '@/components/along/ConsoleNav';
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
      <ConsoleNav city={city} />
      <AuditDrawer targetId="commission.rate" targetLabel="Global commission config" />
    </>
  );
}
