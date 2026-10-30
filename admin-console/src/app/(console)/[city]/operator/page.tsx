import { getCityBySlug } from '@/lib/city/resolve';
import type { OperatorOverview } from '@/lib/operator/types';
import { checkAdminRole, createClient } from '@/lib/supabase/server';
import { rpcUntyped } from '@/lib/supabase/untyped';
import { OperatorConsole } from './operator-console';

interface PageProps {
  params: Promise<{ city: string }>;
}

async function loadInitialOperatorOverview(): Promise<{
  isOperatorViewer: boolean;
  overview: OperatorOverview | null;
}> {
  const isOperatorViewer = await checkAdminRole(['operator_viewer']);
  if (!isOperatorViewer) {
    return { isOperatorViewer: false, overview: null };
  }

  const to = new Date();
  const from = new Date(to.getTime() - 7 * 86400000);
  const supabase = await createClient();
  const { data, error } = await rpcUntyped(supabase, 'operator_overview', {
    p_from: from.toISOString(),
    p_to: to.toISOString(),
  });

  if (error) {
    console.error('[operator_overview]', error.message);
    return { isOperatorViewer: true, overview: null };
  }

  return { isOperatorViewer: true, overview: data as OperatorOverview };
}

export default async function OperatorPage({ params }: PageProps) {
  const { city: citySlug } = await params;
  const city = await getCityBySlug(citySlug);
  const { isOperatorViewer, overview } = await loadInitialOperatorOverview();

  return (
    <>
      <div className="page-header">
        <h1>Operator overview</h1>
        <p>
          Driver totals for your park or union in <strong>{city?.name ?? citySlug}</strong>. No rider-level data.
        </p>
      </div>
      {!city ? (
        <div className="error-banner" role="alert">
          City &quot;{citySlug}&quot; was not found in the database.
        </div>
      ) : null}
      <OperatorConsole initialOverview={overview} isOperatorViewer={isOperatorViewer} />
    </>
  );
}
