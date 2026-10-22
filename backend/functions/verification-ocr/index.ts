import { corsHeaders, errorResponse, requestId } from '../_shared/http.ts';
import { handleVerificationOcrDefault, verificationOcrRequestSchema } from './handler.ts';

Deno.serve(async (req) => {
  const rid = requestId();

  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders() });
  }

  if (req.method !== 'POST') {
    return errorResponse('VALIDATION', 'Method not allowed', 405, { request_id: rid });
  }

  const authHeader = req.headers.get('Authorization');
  if (!authHeader?.startsWith('Bearer ')) {
    return errorResponse('UNAUTHENTICATED', 'Service authorization required', 401, {
      request_id: rid,
    });
  }

  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return errorResponse('VALIDATION', 'Invalid JSON body', 400, { request_id: rid });
  }

  const parsed = verificationOcrRequestSchema.safeParse(body);
  if (!parsed.success) {
    return errorResponse('VALIDATION', parsed.error.message, 400, { request_id: rid });
  }

  try {
    return await handleVerificationOcrDefault(parsed.data, authHeader);
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Internal error';
    return errorResponse('VALIDATION', message, 500, { request_id: rid });
  }
});

export { handleVerificationOcrDefault, verificationOcrRequestSchema };
