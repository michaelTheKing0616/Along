import type { CorridorAnalyticsResponse, CorridorOption } from '@/lib/analytics/types';
import { getCityBySlug } from '@/lib/city/resolve';
import { createClient } from '@/lib/supabase/server';
import { loadCorridorAnalyticsPage } from './actions';
import { CorridorAnalytics } from './corridor-analytics';

interface PageProps {
  params: Promise<{ city: string }>;
}

async function loadCorridors(cityId: string): Promise<CorridorOption[]> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from('corridors')
    .select('id, name, slug')
    .eq('city_id', cityId)
    .order('name');

  if (error || !data) return [];
  return data;
}

async function loadInitialAnalytics(
  corridorId: string
): Promise<CorridorAnalyticsResponse | null> {
  const result = await loadCorridorAnalyticsPage(corridorId, null);
  return result.ok ? (result.data ?? null) : null;
}

export default async function AnalyticsPage({ params }: PageProps) {
  const { city: citySlug } = await params;
  const city = await getCityBySlug(citySlug);
  const corridors = city ? await loadCorridors(city.id) : [];
  const initialCorridorId = corridors[0]?.id ?? null;
  const initialData = initialCorridorId ? await loadInitialAnalytics(initialCorridorId) : null;

  return (
    <>
      <div className="page-header">
        <h1>Corridor analytics</h1>
        <p>
          Time series and coverage gaps for <strong>{city?.name ?? citySlug}</strong>. Conversion
          metrics are diagnostic only.
        </p>
      </div>
      {!city ? (
        <div className="error-banner" role="alert">
          City &quot;{citySlug}&quot; was not found in the database.
        </div>
      ) : corridors.length === 0 ? (
        <div className="error-banner" role="alert">
          No corridors configured for this city.
        </div>
      ) : null}
      {city && corridors.length > 0 ? (
        <CorridorAnalytics
          citySlug={citySlug}
          corridors={corridors}
          initialCorridorId={initialCorridorId}
          initialData={initialData}
          loadPage={loadCorridorAnalyticsPage}
        />
      ) : null}
    </>
  );
}
