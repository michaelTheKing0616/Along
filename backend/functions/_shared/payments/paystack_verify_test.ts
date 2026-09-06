import { assertEquals } from 'jsr:@std/assert@1';
import { verifyPaystackSignature } from './paystack_verify.ts';

const SECRET = 'sk_test_secret';

async function sign(body: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(SECRET),
    { name: 'HMAC', hash: 'SHA-512' },
    false,
    ['sign'],
  );
  const digest = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(body));
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

Deno.test('verifyPaystackSignature: valid HMAC-SHA512', async () => {
  const body = '{"event":"charge.success"}';
  const sig = await sign(body);
  assertEquals(await verifyPaystackSignature(body, sig, SECRET), true);
});

Deno.test('verifyPaystackSignature: rejects tampered body', async () => {
  const body = '{"event":"charge.success"}';
  const sig = await sign(body);
  assertEquals(await verifyPaystackSignature(body + ' ', sig, SECRET), false);
});
