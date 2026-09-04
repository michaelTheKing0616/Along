import { z } from 'zod';
import { loadPlacesCfg } from '../_shared/cfg.ts';
import { errorResponse, jsonResponse, requestId } from '../_shared/http.ts';
import { createPhotonClient, type PhotonClient } from '../_shared/photon.ts';
import { createServiceClient, createUserClient } from '../_shared/supabase.ts';
import type { PlaceResult } from '../_shared/types.ts';

const pointSchema = z.object({
  lat: z.number().min(-90).max(90),
  lng: z.number().min(-180).max(180),
});

export const placesSearchRequestSchema = z.object({
  q: z.string().min(2),
  near: pointSchema,
  city_id: z.string().uuid(),
  limit: z.number().int().min(1).max(8),
});

export type PlacesSearchRequest = z.infer<typeof placesSearchRequestSchema>;

type GraphRow = {
  kind: 'park' | 'stage';
  id: string;
  name: string;
  area: string;
  lat: number;
  lng: number;
  distance_m: number;
};

export type PlacesSearchDeps = {
  service?: ReturnType<typeof createServiceClient>;
  user?: ReturnType<typeof createUserClient>;
  photon?: PhotonClient;
};

function mapGraphRow(row: GraphRow): PlaceResult {
  return {
    kind: row.kind,
    id: row.id,
    name: row.name,
    area: row.area,
    location: { lat: row.lat, lng: row.lng },
    distance_m: Number(row.distance_m),
  };
}

export async function handlePlacesSearch(
  req: PlacesSearchRequest,
  authHeader: string,
  deps?: PlacesSearchDeps,
): Promise<Response> {
  const rid = requestId();
  let degraded = false;

  const userClient = deps?.user ?? createUserClient(authHeader);
  const service = deps?.service ?? createServiceClient();

  const { data: authData, error: authError } = await userClient.auth.getUser();
  if (authError || !authData.user) {
    return errorResponse('UNAUTHENTICATED', 'Authentication required', 401, {
      request_id: rid,
    });
  }

  const { q, near, city_id: cityId, limit } = req;
  const placesCfg = await loadPlacesCfg(service, cityId);

  const { data: graphRows, error: graphError } = await service.rpc('places_search_graph', {
    p_q: q,
    p_near_lat: near.lat,
    p_near_lng: near.lng,
    p_city_id: cityId,
    p_limit: limit,
    p_radius_m: placesCfg.searchRadiusM,
    p_min_similarity: placesCfg.trigramMinSimilarity,
  });
  if (graphError) {
    return errorResponse('VALIDATION', graphError.message, 400, { request_id: rid });
  }

  const graphResults = ((graphRows ?? []) as GraphRow[]).map(mapGraphRow);
  const remaining = Math.max(0, limit - graphResults.length);

  let photonResults: PlaceResult[] = [];
  if (remaining > 0) {
    const photon = deps?.photon ?? createPhotonClient({
      timeoutMs: placesCfg.photonTimeoutMs,
    });
    const photonRes = await photon.search(q, near, remaining);
    if (photonRes.degraded) degraded = true;
    photonResults = photonRes.results;
  }

  const results = [...graphResults, ...photonResults].slice(0, limit);

  return jsonResponse(
    {
      data: { results },
      meta: { request_id: rid, degraded: degraded || undefined },
    },
    200,
    { 'Access-Control-Allow-Origin': '*' },
  );
}
