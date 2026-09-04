import { AuditDrawer } from '@/components/along/AuditDrawer';

interface PageProps {
  params: Promise<{ city: string }>;
}

export default async function AuditPage({ params }: PageProps) {
  const { city } = await params;

  return (
    <>
      <div className="page-header">
        <h1>Audit log</h1>
        <p>Recent admin actions — {city}</p>
      </div>
      <AuditDrawer targetId="commission.rate" targetLabel="Sample entity" />
    </>
  );
}
