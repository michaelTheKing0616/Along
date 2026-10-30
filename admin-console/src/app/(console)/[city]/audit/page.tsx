import { fetchAuditLogPage } from '@/lib/supabase/server';
import { AuditViewer } from './audit-viewer';

interface PageProps {
  params: Promise<{ city: string }>;
}

export default async function AuditPage({ params }: PageProps) {
  const { city } = await params;
  const initialPage = await fetchAuditLogPage({});

  return (
    <>
      <div className="page-header">
        <h1>Audit log</h1>
        <p>
          Every admin action in <strong>{city}</strong>. Select a row to compare the before and after payloads.
        </p>
      </div>
      <AuditViewer citySlug={city} initialPage={initialPage} />
    </>
  );
}
