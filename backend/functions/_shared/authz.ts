import { errorResponse } from './http.ts';

export class AuthzError extends Error {
  constructor(
    message: string,
    readonly code: 'UNAUTHENTICATED' | 'FORBIDDEN',
    readonly status: 401 | 403,
  ) {
    super(message);
    this.name = 'AuthzError';
  }
}

/** Caller of an internal edge function. User JWTs are not service role. */
export type ServiceCaller = {
  serviceRole: boolean;
};

export function extractBearerToken(authorization: string | null): string | null {
  if (!authorization) return null;
  const match = /^Bearer\s+(\S+)$/i.exec(authorization.trim());
  return match?.[1] ?? null;
}

function timingSafeEqual(a: string, b: string): boolean {
  const encoder = new TextEncoder();
  const left = encoder.encode(a);
  const right = encoder.encode(b);
  const length = Math.max(left.length, right.length);
  let diff = left.length === right.length ? 0 : 1;
  for (let i = 0; i < length; i++) {
    const l = i < left.length ? left[i]! : 0;
    const r = i < right.length ? right[i]! : 0;
    diff |= l ^ r;
  }
  return diff === 0;
}

/**
 * True only when the bearer token is the service-role key.
 * A valid user JWT is not enough: several functions then act with the service role.
 */
export function isServiceRoleAuthorization(
  authorization: string | null,
  serviceRoleKey: string | undefined = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY'),
): boolean {
  const token = extractBearerToken(authorization);
  if (!token || !serviceRoleKey) return false;
  return timingSafeEqual(token, serviceRoleKey);
}

export function serviceCallerFromAuthorization(
  authorization: string | null,
  serviceRoleKey?: string,
): ServiceCaller {
  return {
    serviceRole: isServiceRoleAuthorization(authorization, serviceRoleKey),
  };
}

/** Returns a 403 response when the caller is not the service role. */
export function forbiddenUnlessServiceRole(
  caller: ServiceCaller | undefined,
  requestId: string,
): Response | null {
  if (caller?.serviceRole) return null;
  return errorResponse('FORBIDDEN', 'Service role required', 403, {
    request_id: requestId,
  });
}
