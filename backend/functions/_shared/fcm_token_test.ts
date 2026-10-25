import { assertEquals } from 'jsr:@std/assert@1';
import {
  clearFcmTokenCacheForTests,
  exchangeServiceAccountJwt,
  getFcmAccessToken,
  parseFcmServiceAccount,
  resolveFcmProjectId,
} from './fcm_token.ts';
import { createFcmClient } from './fcm.ts';

async function exportPkcs8Pem(key: CryptoKey): Promise<string> {
  const exported = await crypto.subtle.exportKey('pkcs8', key);
  const b64 = btoa(String.fromCharCode(...new Uint8Array(exported)));
  return `-----BEGIN PRIVATE KEY-----\n${b64}\n-----END PRIVATE KEY-----\n`;
}

async function createTestServiceAccount(): Promise<{
  json: string;
  projectId: string;
}> {
  const { privateKey } = await crypto.subtle.generateKey(
    {
      name: 'RSASSA-PKCS1-v1_5',
      modulusLength: 2048,
      publicExponent: new Uint8Array([1, 0, 1]),
      hash: 'SHA-256',
    },
    true,
    ['sign'],
  );

  const pem = await exportPkcs8Pem(privateKey);
  const projectId = 'along-fcm-test';
  const json = JSON.stringify({
    project_id: projectId,
    client_email: 'fcm-test@along-fcm-test.iam.gserviceaccount.com',
    private_key: pem,
    token_uri: 'https://oauth2.test/token',
  });
  return { json, projectId };
}

Deno.test('parseFcmServiceAccount: rejects missing fields', () => {
  let failed = false;
  try {
    parseFcmServiceAccount('{"project_id":"x"}');
  } catch (err) {
    failed = err instanceof Error && err.message.includes('missing client_email or private_key');
  }
  assertEquals(failed, true);
});

Deno.test('resolveFcmProjectId: prefers env over service account', () => {
  const prev = Deno.env.get('FCM_PROJECT_ID');
  Deno.env.set('FCM_PROJECT_ID', 'env-project');
  try {
    assertEquals(
      resolveFcmProjectId({ project_id: 'sa-project', client_email: 'a@b.c', private_key: 'x' }),
      'env-project',
    );
  } finally {
    if (prev) Deno.env.set('FCM_PROJECT_ID', prev);
    else Deno.env.delete('FCM_PROJECT_ID');
  }
});

Deno.test('exchangeServiceAccountJwt: posts JWT bearer grant', async () => {
  const { json } = await createTestServiceAccount();
  const account = parseFcmServiceAccount(json);

  let capturedBody = '';
  // deno-lint-ignore require-await -- test double satisfies an async interface
  const token = await exchangeServiceAccountJwt(account, async (_url, init) => {
    capturedBody = String(init.body);
    return new Response(JSON.stringify({
      access_token: 'oauth-test-token',
      expires_in: 3600,
    }), { status: 200 });
  });

  assertEquals(token.accessToken, 'oauth-test-token');
  assertEquals(capturedBody.includes('grant_type='), true);
  assertEquals(capturedBody.includes('assertion='), true);
});

Deno.test('getFcmAccessToken: caches until expiry', async () => {
  clearFcmTokenCacheForTests();
  const { json } = await createTestServiceAccount();
  const prevAccount = Deno.env.get('FCM_SERVICE_ACCOUNT');
  Deno.env.set('FCM_SERVICE_ACCOUNT', json);

  let fetchCount = 0;
  // deno-lint-ignore require-await -- test double satisfies an async interface
  const fetchFn = async () => {
    fetchCount += 1;
    return new Response(JSON.stringify({
      access_token: `token-${fetchCount}`,
      expires_in: 3600,
    }), { status: 200 });
  };

  try {
    const first = await getFcmAccessToken(fetchFn);
    const second = await getFcmAccessToken(fetchFn);
    assertEquals(first, 'token-1');
    assertEquals(second, 'token-1');
    assertEquals(fetchCount, 1);
  } finally {
    clearFcmTokenCacheForTests();
    if (prevAccount) Deno.env.set('FCM_SERVICE_ACCOUNT', prevAccount);
    else Deno.env.delete('FCM_SERVICE_ACCOUNT');
  }
});

Deno.test('fcm client: stub when FCM env missing', async () => {
  const prevAccount = Deno.env.get('FCM_SERVICE_ACCOUNT');
  const prevProject = Deno.env.get('FCM_PROJECT_ID');
  Deno.env.delete('FCM_SERVICE_ACCOUNT');
  Deno.env.delete('FCM_PROJECT_ID');
  clearFcmTokenCacheForTests();

  try {
    const client = createFcmClient(() =>
      Promise.reject(new Error('fetch should not be called without FCM config'))
    );
    const result = await client.sendDataMessage({
      token: 'device-token',
      data: { trip_id: 'trip-1' },
      ttlSeconds: 25,
    });
    assertEquals(result.messageId, 'stub-no-fcm-config');
  } finally {
    clearFcmTokenCacheForTests();
    if (prevAccount) Deno.env.set('FCM_SERVICE_ACCOUNT', prevAccount);
    if (prevProject) Deno.env.set('FCM_PROJECT_ID', prevProject);
  }
});

Deno.test('fcm client: sends HTTP when service account configured', async () => {
  clearFcmTokenCacheForTests();
  const { json, projectId } = await createTestServiceAccount();
  const prevAccount = Deno.env.get('FCM_SERVICE_ACCOUNT');
  const prevProject = Deno.env.get('FCM_PROJECT_ID');
  Deno.env.set('FCM_SERVICE_ACCOUNT', json);
  Deno.env.set('FCM_PROJECT_ID', projectId);

  try {
    const calls: Array<{ url: string; auth?: string }> = [];
    const client = createFcmClient((url, init) => {
      const auth = (init.headers as Record<string, string> | undefined)?.Authorization;
      calls.push({ url, auth });
      if (url.includes('oauth2.test/token')) {
        return Promise.resolve({
          ok: true,
          status: 200,
          body: JSON.stringify({ access_token: 'minted-token', expires_in: 3600 }),
        });
      }
      return Promise.resolve({
        ok: true,
        status: 200,
        body: '{"name":"projects/along/messages/abc"}',
      });
    });

    const result = await client.sendDataMessage({
      token: 'device-token',
      data: { type: 'trip_request', trip_id: 'trip-1' },
      ttlSeconds: 25,
      collapseKey: 'trip_trip-1',
      priority: 'high',
    });

    assertEquals(result.messageId, 'projects/along/messages/abc');
    assertEquals(calls.length, 2);
    assertEquals(calls[0]?.url, 'https://oauth2.test/token');
    assertEquals(calls[1]?.url.includes(projectId), true);
    assertEquals(calls[1]?.auth, 'Bearer minted-token');
  } finally {
    clearFcmTokenCacheForTests();
    if (prevAccount) Deno.env.set('FCM_SERVICE_ACCOUNT', prevAccount);
    else Deno.env.delete('FCM_SERVICE_ACCOUNT');
    if (prevProject) Deno.env.set('FCM_PROJECT_ID', prevProject);
    else Deno.env.delete('FCM_PROJECT_ID');
  }
});
