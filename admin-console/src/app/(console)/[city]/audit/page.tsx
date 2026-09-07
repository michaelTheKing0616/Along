import { ConsoleNav } from '@/components/along/ConsoleNav';
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
          Filterable, paginated admin actions for <strong>{city}</strong> — select a row to inspect
          JSON before/after payloads.
        </p>
      </div>
      <ConsoleNav city={city} />
      <AuditViewer citySlug={city} initialPage={initialPage} />
    </>
  );
}
