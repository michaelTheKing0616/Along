import { assertEquals } from 'jsr:@std/assert@1';
import {
  extractBearerToken,
  forbiddenUnlessServiceRole,
  isServiceRoleAuthorization,
  serviceCallerFromAuthorization,
} from './authz.ts';

const SERVICE_KEY = 'service-role-key-not-a-user-jwt';

Deno.test('extractBearerToken requires a Bearer scheme', () => {
  assertEquals(extractBearerToken(null), null);
  assertEquals(extractBearerToken('Basic abc'), null);
  assertEquals(extractBearerToken('Bearer user-jwt'), 'user-jwt');
});

Deno.test('isServiceRoleAuthorization rejects a user JWT', () => {
  assertEquals(
    isServiceRoleAuthorization('Bearer user-jwt', SERVICE_KEY),
    false,
  );
  assertEquals(
    isServiceRoleAuthorization(`Bearer ${SERVICE_KEY}`, SERVICE_KEY),
    true,
  );
  assertEquals(isServiceRoleAuthorization('Bearer user-jwt', undefined), false);
});

Deno.test('serviceCallerFromAuthorization marks only the service role', () => {
  assertEquals(
    serviceCallerFromAuthorization('Bearer user-jwt', SERVICE_KEY),
    { serviceRole: false },
  );
  assertEquals(
    serviceCallerFromAuthorization(`Bearer ${SERVICE_KEY}`, SERVICE_KEY),
    { serviceRole: true },
  );
});

Deno.test('forbiddenUnlessServiceRole rejects a non-service caller', async () => {
  const denied = forbiddenUnlessServiceRole({ serviceRole: false }, 'rid-1');
  assertEquals(denied?.status, 403);
  const body = await denied!.json();
  assertEquals(body.error.code, 'FORBIDDEN');

  assertEquals(forbiddenUnlessServiceRole({ serviceRole: true }, 'rid-1'), null);
  assertEquals(forbiddenUnlessServiceRole(undefined, 'rid-1')?.status, 403);
});
