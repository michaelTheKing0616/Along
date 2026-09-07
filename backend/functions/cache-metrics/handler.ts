import { allCacheStats } from '../_shared/edge_cache.ts';
import { jsonResponse, requestId } from '../_shared/http.ts';

export function handleCacheMetrics(): Response {
  const rid = requestId();
  const stats = allCacheStats();

  return jsonResponse(
    {
      data: stats,
      meta: { request_id: rid },
    },
    200,
    { 'Access-Control-Allow-Origin': '*' },
  );
}
