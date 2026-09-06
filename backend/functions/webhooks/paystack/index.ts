import { errorResponse, requestId } from '../../_shared/http.ts';
import { handlePaystackWebhookDefault } from './handler.ts';

Deno.serve(async (req) => {
  const rid = requestId();

  if (req.method !== 'POST') {
    return errorResponse('VALIDATION', 'Method not allowed', 405, { request_id: rid });
  }

  try {
    return await handlePaystackWebhookDefault(req);
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Internal error';
    return errorResponse('VALIDATION', message, 500, { request_id: rid });
  }
});

export { handlePaystackWebhookDefault, paystackEventSchema } from './handler.ts';
