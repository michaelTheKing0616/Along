import { forbiddenUnlessServiceRole, type ServiceCaller } from '../_shared/authz.ts';
import { allCacheStats } from '../_shared/edge_cache.ts';
import { jsonResponse, requestId } from '../_shared/http.ts';

export function handleCacheMetrics(caller?: ServiceCaller): Response {
  const rid = requestId();
  const denied = forbiddenUnlessServiceRole(caller, rid);
  if (denied) return denied;

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
