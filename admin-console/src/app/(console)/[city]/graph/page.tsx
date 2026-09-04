import { ConsoleNav } from '@/components/along/ConsoleNav';
import { getCityBySlug } from '@/lib/city/resolve';
import { createAdminClient } from '@/lib/supabase/admin';
import { createClient } from '@/lib/supabase/server';
import { GraphEditor } from './graph-editor';

interface PageProps {
  params: Promise<{ city: string }>;
}

export type GraphPark = {
  id: string;
  name: string;
  name_aliases: string[];
  verification_status: string;
  confidence_score: number;
};

export type GraphStage = {
  id: string;
  route_id: string;
  sequence: number;
  name: string | null;
  verification_status: string;
  confidence_score: number;
};

export type GraphRoute = {
  id: string;
  corridor_id: string | null;
  name: string | null;
  mode_code: string;
  verification_status: string;
  confidence_score: number;
  origin_park_id: string;
  destination_park_id: string;
  active: boolean;
};

export type GraphCorridor = {
  id: string;
  name: string;
  slug: string;
  status: string;
};

async function loadGraph(cityId: string) {
  const supabase = await createClient();
  const admin = createAdminClient();

  const [corridorsRes, routesRes, stagesRes, parksRes] = await Promise.all([
    admin.from('corridors').select('id, name, slug, status').eq('city_id', cityId).order('name'),
    supabase
      .from('routes')
      .select(
        'id, corridor_id, name, mode_code, verification_status, confidence_score, origin_park_id, destination_park_id, active'
      )
      .eq('city_id', cityId)
      .order('mode_code'),
    supabase
      .from('route_stages')
      .select('id, route_id, sequence, name, verification_status, confidence_score')
      .order('sequence'),
    supabase
      .from('parks')
      .select('id, name, name_aliases, verification_status, confidence_score')
      .eq('city_id', cityId)
      .order('name'),
  ]);

  const routes = (routesRes.data ?? []) as GraphRoute[];
  const routeIds = new Set(routes.map((r) => r.id));
  const stages = ((stagesRes.data ?? []) as GraphStage[]).filter((s) => routeIds.has(s.route_id));

  return {
    corridors: (corridorsRes.data ?? []) as GraphCorridor[],
    routes,
    stages,
    parks: (parksRes.data ?? []) as GraphPark[],
  };
}

export default async function GraphEditorPage({ params }: PageProps) {
  const { city: citySlug } = await params;
  const city = await getCityBySlug(citySlug);
  const graph = city
    ? await loadGraph(city.id)
    : { corridors: [], routes: [], stages: [], parks: [] };

  return (
    <>
      <div className="page-header">
        <h1>Graph editor</h1>
        <p>
          Read and edit parks, routes, and stages for <strong>{city?.name ?? citySlug}</strong>.
          Saves write <code>graph_revisions</code> via database triggers. Field publish remains on
          the reconciliation queue.
        </p>
      </div>
      {!city ? (
        <div className="error-banner" role="alert">
          City &quot;{citySlug}&quot; was not found in the database.
        </div>
      ) : null}
      <ConsoleNav city={citySlug} />
      <GraphEditor citySlug={citySlug} graph={graph} />
    </>
  );
}
