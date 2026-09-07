import { corsHeaders, errorResponse, requestId } from '../_shared/http.ts';
import { handleCacheMetrics } from './handler.ts';

Deno.serve((req) => {
  const rid = requestId();

  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders() });
  }

  if (req.method !== 'GET') {
    return errorResponse('VALIDATION', 'Method not allowed', 405, { request_id: rid });
  }

  return handleCacheMetrics();
});

export { handleCacheMetrics } from './handler.ts';
