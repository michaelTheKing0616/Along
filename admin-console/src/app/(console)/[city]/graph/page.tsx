import { ConsoleNav } from '@/components/along/ConsoleNav';
import { getCityBySlug } from '@/lib/city/resolve';
import type { GraphMapPoint, GraphMapRoute } from '@/lib/graph/types';
import { parseGeoPoint } from '@/lib/safety/format';
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
  lat: number;
  lng: number;
};

export type GraphStage = {
  id: string;
  route_id: string;
  sequence: number;
  name: string | null;
  verification_status: string;
  confidence_score: number;
  lat: number;
  lng: number;
  is_official_park: boolean;
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

function pointFromLocation(location: unknown): { lat: number; lng: number } | null {
  return parseGeoPoint(location);
}

async function loadGraph(cityId: string) {
  const supabase = await createClient();

  const [corridorsRes, routesRes, stagesRes, parksRes] = await Promise.all([
    supabase.from('corridors').select('id, name, slug, status').eq('city_id', cityId).order('name'),
    supabase
      .from('routes')
      .select(
        'id, corridor_id, name, mode_code, verification_status, confidence_score, origin_park_id, destination_park_id, active'
      )
      .eq('city_id', cityId)
      .order('mode_code'),
    supabase
      .from('route_stages')
      .select(
        'id, route_id, sequence, name, location, verification_status, confidence_score, is_official_park'
      )
      .order('sequence'),
    supabase
      .from('parks')
      .select('id, name, name_aliases, location, verification_status, confidence_score')
      .eq('city_id', cityId)
      .order('name'),
  ]);

  const routes = (routesRes.data ?? []) as GraphRoute[];
  const routeIds = new Set(routes.map((r) => r.id));
  const stagesRaw = ((stagesRes.data ?? []) as Array<Omit<GraphStage, 'lat' | 'lng'> & { location: unknown }>).filter(
    (s) => routeIds.has(s.route_id)
  );

  const stages: GraphStage[] = stagesRaw.map((stage) => {
    const point = pointFromLocation(stage.location);
    return {
      id: stage.id,
      route_id: stage.route_id,
      sequence: stage.sequence,
      name: stage.name,
      verification_status: stage.verification_status,
      confidence_score: stage.confidence_score,
      is_official_park: stage.is_official_park,
      lat: point?.lat ?? 9.057,
      lng: point?.lng ?? 7.495,
    };
  });

  const parks: GraphPark[] = ((parksRes.data ?? []) as Array<
    Omit<GraphPark, 'lat' | 'lng'> & { location: unknown }
  >).map((park) => {
    const point = pointFromLocation(park.location);
    return {
      id: park.id,
      name: park.name,
      name_aliases: park.name_aliases,
      verification_status: park.verification_status,
      confidence_score: park.confidence_score,
      lat: point?.lat ?? 9.057,
      lng: point?.lng ?? 7.495,
    };
  });

  const stagesByRoute = new Map<string, GraphStage[]>();
  for (const stage of stages) {
    const list = stagesByRoute.get(stage.route_id) ?? [];
    list.push(stage);
    stagesByRoute.set(stage.route_id, list);
  }
  for (const [, list] of stagesByRoute) {
    list.sort((a, b) => a.sequence - b.sequence);
  }

  const mapRoutes: GraphMapRoute[] = routes.flatMap((route) => {
    const routeStages = stagesByRoute.get(route.id) ?? [];
    if (routeStages.length < 2) return [];
    return [
      {
        id: route.id,
        mode_code: route.mode_code,
        verification_status: route.verification_status as GraphMapRoute['verification_status'],
        coordinates: routeStages.map((s) => [s.lng, s.lat] as [number, number]),
      },
    ];
  });

  const mapParks: GraphMapPoint[] = parks.map((park) => ({
    id: park.id,
    name: park.name,
    lat: park.lat,
    lng: park.lng,
    verification_status: park.verification_status as GraphMapPoint['verification_status'],
  }));

  const mapStages: GraphMapPoint[] = stages.map((stage) => ({
    id: stage.id,
    name: stage.name ?? `Stage ${stage.sequence}`,
    lat: stage.lat,
    lng: stage.lng,
    verification_status: stage.verification_status as GraphMapPoint['verification_status'],
    route_id: stage.route_id,
    is_official_park: stage.is_official_park,
  }));

  return {
    corridors: (corridorsRes.data ?? []) as GraphCorridor[],
    routes,
    stages,
    parks,
    mapRoutes,
    mapParks,
    mapStages,
    mapCenter: mapParks[0]
      ? { lat: mapParks[0].lat, lng: mapParks[0].lng }
      : { lat: 9.0765, lng: 7.3986 },
  };
}

export default async function GraphEditorPage({ params }: PageProps) {
  const { city: citySlug } = await params;
  const city = await getCityBySlug(citySlug);
  const graph = city
    ? await loadGraph(city.id)
    : {
        corridors: [],
        routes: [],
        stages: [],
        parks: [],
        mapRoutes: [],
        mapParks: [],
        mapStages: [],
        mapCenter: { lat: 9.0765, lng: 7.3986 },
      };

  return (
    <>
      <div className="page-header">
        <h1>Graph editor</h1>
        <p>
          Read and edit parks, routes, and stages for <strong>{city?.name ?? citySlug}</strong>.
          Saves go through <code>admin_update_graph_entity</code> (one RPC per entity) and write{' '}
          <code>graph_revisions</code> + audit. Field publish remains on the reconciliation queue.
        </p>
      </div>
      {!city ? (
        <div className="error-banner" role="alert">
          City &quot;{citySlug}&quot; was not found in the database.
        </div>
      ) : null}
      <ConsoleNav city={citySlug} />
      <GraphEditor
        citySlug={citySlug}
        cityId={city?.id ?? ''}
        graph={graph}
        parkNames={graph.parks.map((p) => p.name)}
      />
    </>
  );
}
