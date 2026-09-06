import { assertEquals } from 'jsr:@std/assert@1';
import type { SupabaseClient } from '@supabase/supabase-js';
import { handleQrResolve } from './handler.ts';

function createMockService(options: {
  allowed?: boolean;
  resolveData?: Record<string, unknown> | null;
  resolveError?: { message: string } | null;
}): SupabaseClient {
  return {
    rpc: (name: string) => {
      if (name === 'check_qr_resolve_rate') {
        return Promise.resolve({ data: options.allowed ?? true, error: null });
      }
      if (name === 'resolve_qr_driver') {
        if (options.resolveError) {
          return Promise.resolve({ data: null, error: options.resolveError });
        }
        return Promise.resolve({ data: options.resolveData, error: null });
      }
      return Promise.resolve({ data: null, error: null });
    },
  } as unknown as SupabaseClient;
}

Deno.test('TS-QR-01: qr/resolve returns driver identity for known code', async () => {
  const res = await handleQrResolve('QRDRV060', null, {
    service: createMockService({
      resolveData: {
        driver: { first_name: 'Musa', plate: 'ABC-123', mode: 'car', accepts_digital: true, active: true },
        suggested_amounts: [],
        currency: 'NGN',
        min_amount: { amount: 100, currency: 'NGN' },
      },
    }),
    clientIp: '10.0.0.1',
  });

  assertEquals(res.status, 200);
  const json = await res.json();
  assertEquals(json.data.driver.first_name, 'Musa');
});

Deno.test('TS-QR-01: qr/resolve unknown code → 404', async () => {
  const res = await handleQrResolve('BADCODE1', null, {
    service: createMockService({
      resolveError: { message: 'NOT_FOUND' },
    }),
    clientIp: '10.0.0.2',
  });

  assertEquals(res.status, 404);
});

Deno.test('TS-QR-01: qr/resolve rate limit → 429', async () => {
  const res = await handleQrResolve('QRDRV060', null, {
    service: createMockService({ allowed: false }),
    clientIp: '10.0.0.3',
  });

  assertEquals(res.status, 429);
});
