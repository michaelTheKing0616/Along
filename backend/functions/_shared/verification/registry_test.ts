import { assertEquals, assertThrows } from 'jsr:@std/assert@1';
import { resolveVerificationProvider } from './registry.ts';

Deno.test('verification registry: resolves verifyme stub', async () => {
  const provider = resolveVerificationProvider('verifyme');
  const result = await provider.runOcr('driver/nin/front.jpg', 'nin');
  assertEquals(result.provider, 'verifyme');
  assertEquals(result.provider_reference.startsWith('stub-verifyme-'), true);
});

Deno.test('verification registry: unknown provider throws', () => {
  assertThrows(
    () => resolveVerificationProvider('unknown-vendor'),
    Error,
    'UNKNOWN_VERIFICATION_PROVIDER:unknown-vendor',
  );
});
