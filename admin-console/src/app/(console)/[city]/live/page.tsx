import dynamic from 'next/dynamic';
import { ConsoleNav } from '@/components/along/ConsoleNav';
import { parseLiveMapStaticPayload } from '@/lib/map/parse';
import type { LiveMapStaticPayload } from '@/lib/map/types';
import { getCityBySlug } from '@/lib/city/resolve';
import { createClient } from '@/lib/supabase/server';

const AdminLiveMap = dynamic(
  () => import('@/components/along/AdminLiveMap').then((mod) => mod.AdminLiveMap),
  {
    ssr: false,
    loading: () => <div className="live-map-loading card">Loading live map…</div>,
  }
);

interface PageProps {
  params: Promise<{ city: string }>;
}

async function loadStaticLayers(cityId: string): Promise<LiveMapStaticPayload> {
  const supabase = await createClient();

  const [parksRes, routesRes, stagesRes, gapsRes, sosRes] = await Promise.all([
    supabase
      .from('parks')
      .select('id, name, location, verification_status')
      .eq('city_id', cityId)
      .eq('active', true),
    supabase
      .from('routes')
      .select('id, mode_code, verification_status, path')
      .eq('city_id', cityId)
      .eq('active', true),
    supabase
      .from('route_stages')
      .select(
        'id, route_id, name, location, verification_status, is_official_park, sequence, routes!inner(city_id)'
      )
      .eq('routes.city_id', cityId)
      .order('sequence'),
    supabase
      .from('coverage_gap_reports')
      .select(
        'id, searched_location, ambient_vehicle_count, nearest_known_stage_distance_m, searched_at'
      )
      .eq('city_id', cityId)
      .gte('searched_at', new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString())
      .order('searched_at', { ascending: false })
      .limit(500),
    supabase
      .from('sos_alerts')
      .select(
        `
        id,
        trip_id,
        status,
        created_at,
        location,
        profiles!sos_alerts_raised_by_fkey ( display_name ),
        trips (
          rider:profiles!trips_rider_id_fkey ( display_name ),
          driver:profiles!trips_driver_id_fkey ( display_name ),
          vehicles ( plate_number ),
          journeys ( city_id )
        )
      `
      )
      .in('status', ['open', 'acknowledged'])
      .order('created_at', { ascending: true }),
  ]);

  const sosRows = (sosRes.data ?? []).filter((row) => {
    const journeys = row.trips as { journeys?: { city_id?: string } | null } | null;
    return journeys?.journeys?.city_id == null || journeys.journeys.city_id === cityId;
  });

  return parseLiveMapStaticPayload({
    parks: parksRes.data ?? [],
    routes: routesRes.data ?? [],
    stages: stagesRes.data ?? [],
    coverageGaps: gapsRes.data ?? [],
    sos: sosRows as Parameters<typeof parseLiveMapStaticPayload>[0]['sos'],
  });
}

function defaultCenter(staticData: LiveMapStaticPayload): { lat: number; lng: number } {
  const firstPark = staticData.parks[0];
  if (firstPark) return { lat: firstPark.lat, lng: firstPark.lng };
  return { lat: 9.0765, lng: 7.3986 };
}

export default async function LiveMapPage({ params }: PageProps) {
  const { city: citySlug } = await params;
  const city = await getCityBySlug(citySlug);
  const staticData = city ? await loadStaticLayers(city.id) : emptyStatic();
  const center = defaultCenter(staticData);

  return (
    <>
      <div className="page-header">
        <h1>Live map</h1>
        <p>
          Tier I ops view for <strong>{city?.name ?? citySlug}</strong> — precise positions,
          routes, active trips, SOS, and coverage-gap heat. Vector tiles only (MapLibre + PMTiles).
        </p>
      </div>
      {!city ? (
        <div className="error-banner" role="alert">
          City &quot;{citySlug}&quot; was not found in the database.
        </div>
      ) : null}
      <ConsoleNav city={citySlug} />
      {city ? (
        <AdminLiveMap
          citySlug={citySlug}
          cityId={city.id}
          cityName={city.name}
          initialStatic={staticData}
          initialCenter={center}
        />
      ) : null}
    </>
  );
}

function emptyStatic(): LiveMapStaticPayload {
  return { parks: [], stages: [], routes: [], coverageGaps: [], sos: [] };
}
