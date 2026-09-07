import { z } from 'zod';
import { loadCacheCfg } from '../_shared/cfg.ts';
import { getGraphBundleCache, type TtlCache } from '../_shared/edge_cache.ts';
import { errorResponse, jsonResponse, requestId } from '../_shared/http.ts';
import { createServiceClient, createUserClient } from '../_shared/supabase.ts';

export const graphBundleRequestSchema = z.object({
  city_id: z.string().uuid(),
  graph_version: z.string().optional(),
});

export type GraphBundleRequest = z.infer<typeof graphBundleRequestSchema>;

export type GraphBundlePayload = {
  city_id: string;
  graph_version: string;
  parks: unknown[];
  stages: unknown[];
  legs: unknown[];
  truncated: boolean;
};

export type GraphBundleDeps = {
  service?: ReturnType<typeof createServiceClient>;
  user?: ReturnType<typeof createUserClient>;
  cache?: TtlCache<GraphBundlePayload> | false;
};

function cacheKey(cityId: string, graphVersion: string): string {
  return `${cityId}:${graphVersion}`;
}

export async function handleGraphBundle(
  req: GraphBundleRequest,
  authHeader: string,
  deps?: GraphBundleDeps,
): Promise<Response> {
  const rid = requestId();
  const userClient = deps?.user ?? createUserClient(authHeader);
  const service = deps?.service ?? createServiceClient();
  const cache = deps?.cache === false ? null : (deps?.cache ?? getGraphBundleCache());

  const { data: authData, error: authError } = await userClient.auth.getUser();
  if (authError || !authData.user) {
    return errorResponse('UNAUTHENTICATED', 'Authentication required', 401, {
      request_id: rid,
    });
  }

  const { city_id: cityId } = req;
  const cacheCfg = await loadCacheCfg(service, cityId);

  const { data: versionRaw, error: versionError } = await service.rpc('city_graph_version', {
    p_city_id: cityId,
  });
  if (versionError) {
    return errorResponse('VALIDATION', versionError.message, 400, { request_id: rid });
  }

  const graphVersion = String(versionRaw ?? '');
  if (req.graph_version && req.graph_version !== graphVersion) {
    // Client stale — fall through to fresh bundle (not an error).
  }

  const key = cacheKey(cityId, graphVersion);
  if (cache) {
    const hit = cache.get(key);
    if (hit) {
      console.log(JSON.stringify({ event: 'cache_hit', cache: 'graph_bundle', key }));
      return jsonResponse(
        { data: hit, meta: { request_id: rid } },
        200,
        {
          'Access-Control-Allow-Origin': '*',
          'X-Cache': 'HIT',
        },
      );
    }
  }

  const { data: bundleRaw, error: bundleError } = await service.rpc('graph_bundle_compact', {
    p_city_id: cityId,
    p_max_parks: cacheCfg.graphBundleMaxParks,
    p_max_stages: cacheCfg.graphBundleMaxStages,
    p_max_legs: cacheCfg.graphBundleMaxLegs,
  });
  if (bundleError) {
    return errorResponse('VALIDATION', bundleError.message, 400, { request_id: rid });
  }

  const bundle = (bundleRaw ?? {}) as {
    parks?: unknown[];
    stages?: unknown[];
    legs?: unknown[];
    truncated?: boolean;
  };

  const payload: GraphBundlePayload = {
    city_id: cityId,
    graph_version: graphVersion,
    parks: bundle.parks ?? [],
    stages: bundle.stages ?? [],
    legs: bundle.legs ?? [],
    truncated: Boolean(bundle.truncated),
  };

  if (cache) {
    cache.set(key, payload, cacheCfg.graphBundleTtlS * 1000);
  }

  console.log(JSON.stringify({ event: 'cache_miss', cache: 'graph_bundle', key }));

  return jsonResponse(
    { data: payload, meta: { request_id: rid } },
    200,
    {
      'Access-Control-Allow-Origin': '*',
      'X-Cache': 'MISS',
    },
  );
}

export function parseGraphBundleRequest(
  method: string,
  url: URL,
  body: unknown,
): { ok: true; data: GraphBundleRequest } | { ok: false; message: string } {
  if (method === 'GET') {
    const parsed = graphBundleRequestSchema.safeParse({
      city_id: url.searchParams.get('city_id'),
      graph_version: url.searchParams.get('graph_version') ?? undefined,
    });
    if (!parsed.success) return { ok: false, message: parsed.error.message };
    return { ok: true, data: parsed.data };
  }

  const parsed = graphBundleRequestSchema.safeParse(body);
  if (!parsed.success) return { ok: false, message: parsed.error.message };
  return { ok: true, data: parsed.data };
}
