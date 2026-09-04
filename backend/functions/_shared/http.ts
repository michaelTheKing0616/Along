export function requestId(): string {
  return crypto.randomUUID();
}

export function jsonResponse(
  body: unknown,
  status = 200,
  headers: Record<string, string> = {},
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json', ...headers },
  });
}

export function errorResponse(
  code: string,
  message: string,
  status: number,
  meta: { request_id: string; degraded?: boolean },
): Response {
  return jsonResponse({ error: { code, message }, meta }, status);
}

export function corsHeaders(): Record<string, string> {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers':
      'authorization, x-client-info, apikey, content-type, idempotency-key',
  };
}
