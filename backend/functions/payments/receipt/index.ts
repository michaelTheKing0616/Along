import { corsHeaders, errorResponse, requestId } from '../../_shared/http.ts';
import { handlePaymentsReceipt } from './handler.ts';

Deno.serve(async (req) => {
  const rid = requestId();

  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders() });
  }

  if (req.method !== 'GET') {
    return errorResponse('VALIDATION', 'Method not allowed', 405, { request_id: rid });
  }

  const url = new URL(req.url);
  const parts = url.pathname.split('/').filter(Boolean);
  const paymentId = parts[parts.length - 1];
  const receiptToken = url.searchParams.get('receipt_token');

  if (!paymentId) {
    return errorResponse('VALIDATION', 'payment_id required', 400, { request_id: rid });
  }

  try {
    return await handlePaymentsReceipt(
      paymentId,
      receiptToken,
      req.headers.get('Authorization'),
    );
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Internal error';
    return errorResponse('VALIDATION', message, 500, { request_id: rid });
  }
});

export { handlePaymentsReceipt } from './handler.ts';
