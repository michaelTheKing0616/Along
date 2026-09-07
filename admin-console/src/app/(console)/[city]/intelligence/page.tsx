import { ConsoleNav } from '@/components/along/ConsoleNav';
import { AuditDrawer } from '@/components/along/AuditDrawer';
import { getCityBySlug } from '@/lib/city/resolve';
import type {
  CandidateParkRow,
  GeometryCorrectionRow,
  RouteInferenceRow,
} from '@/lib/intelligence/types';
import { parseGeoPoint } from '@/lib/safety/format';
import { createClient } from '@/lib/supabase/server';
import { IntelligenceConsole } from './intelligence-console';

interface PageProps {
  params: Promise<{ city: string }>;
}

function pointFromLocation(location: unknown): { lat: number; lng: number } | null {
  return parseGeoPoint(location);
}

async function loadCandidateParks(cityId: string): Promise<CandidateParkRow[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from('candidate_park_clusters')
    .select(
      'id, status, distinct_driver_count, distinct_day_count, sample_count, first_seen, last_seen, centroid, reviewed_at'
    )
    .eq('city_id', cityId)
    .order('created_at', { ascending: false });

  if (error || !data) {
    console.error('[loadCandidateParks]', error?.message);
    return [];
  }

  return data.flatMap((row) => {
    const point = pointFromLocation(row.centroid);
    if (!point) return [];
    return [
      {
        id: row.id,
        status: row.status as CandidateParkRow['status'],
        distinct_driver_count: row.distinct_driver_count,
        distinct_day_count: row.distinct_day_count,
        sample_count: row.sample_count,
        first_seen: row.first_seen,
        last_seen: row.last_seen,
        lat: point.lat,
        lng: point.lng,
        reviewed_at: row.reviewed_at,
      },
    ];
  });
}

async function loadRouteInferences(cityId: string): Promise<RouteInferenceRow[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from('route_inference_candidates')
    .select(
      'id, status, mode_code, supporting_trip_count, created_at, origin_cluster, destination_cluster, route_id, reviewed_at'
    )
    .eq('city_id', cityId)
    .order('created_at', { ascending: false });

  if (error || !data) {
    console.error('[loadRouteInferences]', error?.message);
    return [];
  }

  return data.map((row) => {
    const origin = pointFromLocation(row.origin_cluster);
    const destination = pointFromLocation(row.destination_cluster);
    return {
      id: row.id,
      status: row.status as RouteInferenceRow['status'],
      mode_code: row.mode_code,
      supporting_trip_count: row.supporting_trip_count,
      created_at: row.created_at,
      origin_lat: origin?.lat ?? null,
      origin_lng: origin?.lng ?? null,
      destination_lat: destination?.lat ?? null,
      destination_lng: destination?.lng ?? null,
      route_id: row.route_id,
      reviewed_at: row.reviewed_at,
    };
  });
}

async function loadGeometryCorrections(cityId: string): Promise<GeometryCorrectionRow[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from('road_geometry_corrections')
    .select('id, status, supporting_trace_count, created_at, reviewed_at')
    .eq('city_id', cityId)
    .order('created_at', { ascending: false });

  if (error || !data) {
    console.error('[loadGeometryCorrections]', error?.message);
    return [];
  }

  return data.map((row) => ({
    id: row.id,
    status: row.status as GeometryCorrectionRow['status'],
    supporting_trace_count: row.supporting_trace_count,
    created_at: row.created_at,
    reviewed_at: row.reviewed_at,
  }));
}

export default async function IntelligencePage({ params }: PageProps) {
  const { city: citySlug } = await params;
  const city = await getCityBySlug(citySlug);

  const [candidateParks, routeInferences, geometryCorrections] = city
    ? await Promise.all([
        loadCandidateParks(city.id),
        loadRouteInferences(city.id),
        loadGeometryCorrections(city.id),
      ])
    : [[], [], []];

  const auditTargetId =
    candidateParks.find((r) => r.status === 'new')?.id ??
    routeInferences.find((r) => r.status === 'new')?.id ??
    geometryCorrections.find((r) => r.status === 'candidate')?.id ??
    null;

  return (
    <>
      <div className="page-header">
        <h1>Intelligence review</h1>
        <p>
          Trace-derived candidates for <strong>{city?.name ?? citySlug}</strong> — promote to the
          along graph as <code>candidate</code> rows with provenance, or dismiss.
        </p>
      </div>
      {!city ? (
        <div className="error-banner" role="alert">
          City &quot;{citySlug}&quot; was not found in the database.
        </div>
      ) : null}
      <ConsoleNav city={citySlug} />
      <IntelligenceConsole
        citySlug={citySlug}
        candidateParks={candidateParks}
        routeInferences={routeInferences}
        geometryCorrections={geometryCorrections}
      />
      {auditTargetId ? (
        <AuditDrawer targetId={auditTargetId} targetLabel="intelligence candidate" />
      ) : null}
    </>
  );
}
