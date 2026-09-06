import { assertEquals } from 'https://deno.land/std@0.224.0/assert/mod.ts';
import { signCandidateToken, verifyCandidateToken } from './candidate_token.ts';

Deno.test('candidate_token: sign and verify', async () => {
  const key = 'test-hmac-key-do-not-commit';
  const exp = Math.floor(Date.now() / 1000) + 60;
  const token = await signCandidateToken(key, {
    driverId: '0a100000-0000-4000-8000-000000000001',
    sessionId: '0b100000-0000-4000-8000-000000000001',
    exp,
  });
  const parsed = await verifyCandidateToken(key, token);
  assertEquals(parsed?.driverId, '0a100000-0000-4000-8000-000000000001');
  assertEquals(parsed?.sessionId, '0b100000-0000-4000-8000-000000000001');
});

Deno.test('candidate_token: tampered signature rejected', async () => {
  const key = 'test-hmac-key-do-not-commit';
  const exp = Math.floor(Date.now() / 1000) + 60;
  const token = await signCandidateToken(key, {
    driverId: '0a100000-0000-4000-8000-000000000001',
    sessionId: '0b100000-0000-4000-8000-000000000001',
    exp,
  });
  const tampered = token.slice(0, -4) + 'XXXX';
  const parsed = await verifyCandidateToken(key, tampered);
  assertEquals(parsed, null);
});
