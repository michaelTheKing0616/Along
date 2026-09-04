import { ConsoleNav } from '@/components/along/ConsoleNav';
import { getCityBySlug } from '@/lib/city/resolve';
import { createAdminClient } from '@/lib/supabase/admin';
import { createClient } from '@/lib/supabase/server';
import { DeployPlaybook } from './deploy-playbook';

interface PageProps {
  params: Promise<{ city: string }>;
}

async function loadDeployStats(cityId: string) {
  const supabase = await createClient();
  const admin = createAdminClient();

  const [parksRes, routesRes, corridorsRes] = await Promise.all([
    supabase.from('parks').select('id', { count: 'exact', head: true }).eq('city_id', cityId),
    supabase.from('routes').select('id', { count: 'exact', head: true }).eq('city_id', cityId),
    admin.from('corridors').select('id', { count: 'exact', head: true }).eq('city_id', cityId),
  ]);

  const { data: parkNames } = await supabase.from('parks').select('name').eq('city_id', cityId);

  return {
    parkCount: parksRes.count ?? 0,
    routeCount: routesRes.count ?? 0,
    corridorCount: corridorsRes.count ?? 0,
    parkNames: (parkNames ?? []).map((p) => p.name),
  };
}

export default async function DeployPlaybookPage({ params }: PageProps) {
  const { city: citySlug } = await params;
  const city = await getCityBySlug(citySlug);
  const stats = city
    ? await loadDeployStats(city.id)
    : { parkCount: 0, routeCount: 0, corridorCount: 0, parkNames: [] };

  return (
    <>
      <div className="page-header">
        <h1>City deployment playbook</h1>
        <p>
          Checklist and CSV seed path for <strong>{city?.name ?? citySlug}</strong> (status:{' '}
          <code>{city?.status ?? 'unknown'}</code>).
        </p>
      </div>
      {!city ? (
        <div className="error-banner" role="alert">
          City &quot;{citySlug}&quot; was not found in the database.
        </div>
      ) : null}
      <ConsoleNav city={citySlug} />
      {city ? (
        <DeployPlaybook
          citySlug={citySlug}
          cityId={city.id}
          cityStatus={city.status}
          stats={stats}
        />
      ) : null}
    </>
  );
}
