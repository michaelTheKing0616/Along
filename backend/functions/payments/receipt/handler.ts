import { errorResponse, jsonResponse, requestId } from '../../_shared/http.ts';
import { createServiceClient, createUserClient } from '../../_shared/supabase.ts';

export async function handlePaymentsReceipt(
  paymentId: string,
  receiptToken: string | null,
  authHeader: string | null,
): Promise<Response> {
  const rid = requestId();
  let riderId: string | null = null;

  if (authHeader?.startsWith('Bearer ')) {
    const userClient = createUserClient(authHeader);
    const { data: userData } = await userClient.auth.getUser();
    riderId = userData.user?.id ?? null;
  }

  const service = createServiceClient();
  const { data, error } = await service.rpc('payment_receipt_payload', {
    p_payment_id: paymentId,
    p_receipt_token: receiptToken,
  });

  if (error) {
    const upper = error.message.toUpperCase();
    if (upper.includes('NOT_FOUND')) {
      return errorResponse('NOT_FOUND', 'Receipt not found', 404, { request_id: rid });
    }
    if (upper.includes('FORBIDDEN') || upper.includes('UNAUTHENTICATED')) {
      return errorResponse('FORBIDDEN', 'Not allowed', 403, { request_id: rid });
    }
    return errorResponse('VALIDATION', error.message, 400, { request_id: rid });
  }

  return jsonResponse({ data, meta: { request_id: rid } });
}
