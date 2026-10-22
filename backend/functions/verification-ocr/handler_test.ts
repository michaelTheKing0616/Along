import { assertEquals } from 'jsr:@std/assert@1';
import type { SupabaseClient } from '@supabase/supabase-js';
import { containsIdNumber } from '../_shared/redact_ids.ts';
import {
  handleVerificationOcr,
  type OcrUpstreamResult,
  type VerificationOcrRequest,
} from './handler.ts';

const VERIFICATION_ID = 'f1000000-0000-4000-8000-000000000001';

function createMockService(
  row: Record<string, unknown>,
  updates: Array<Record<string, unknown>>,
): SupabaseClient {
  return {
    from: (table: string) => {
      if (table !== 'driver_verifications') {
        throw new Error(`unexpected table ${table}`);
      }
      return {
        select: () => ({
          eq: () => ({
            single: () => Promise.resolve({ data: row, error: null }),
          }),
        }),
        update: (payload: Record<string, unknown>) => ({
          eq: () => {
            updates.push(payload);
            return Promise.resolve({ error: null });
          },
        }),
      };
    },
    rpc: () =>
      Promise.resolve({
        data: 'deadbeef'.repeat(8),
        error: null,
      }),
  } as unknown as SupabaseClient;
}

async function runOcr(
  documentType: string,
  upstreamFields: Record<string, string>,
): Promise<{ hints: Record<string, string>; ocrExtract: Record<string, unknown> }> {
  const updates: Array<Record<string, unknown>> = [];
  const req: VerificationOcrRequest = { verification_id: VERIFICATION_ID };

  const res = await handleVerificationOcr(req, {
    service: createMockService(
      {
        id: VERIFICATION_ID,
        driver_id: '0a100000-0000-4000-8000-000000000004',
        document_type: documentType,
        storage_path: '0a100000-0000-4000-8000-000000000004/nin/front.jpg',
        country_code: 'NG',
      },
      updates,
    ),
    ocrUpstream: (_path, _documentType, _providerName): Promise<OcrUpstreamResult> =>
      Promise.resolve({
        fields: upstreamFields,
        provider: 'verifyme',
        provider_reference: 'mock-ref',
      }),
    computeHash: () => Promise.resolve('aabbccdd'.repeat(8)),
    caller: { serviceRole: true },
  });

  assertEquals(res.status, 200);
  const body = await res.json();
  return {
    hints: body.data.hints as Record<string, string>,
    ocrExtract: updates[0]?.ocr_extract as Record<string, unknown>,
  };
}

Deno.test('verification-ocr: NIN output has no raw ID numbers', async () => {
  const { hints, ocrExtract } = await runOcr('nin', {
    full_name: 'Ada Okafor',
    id_number: '12345678901',
    dob: '1990-05-15',
  });

  assertEquals(hints.id_number, undefined);
  assertEquals(containsIdNumber(JSON.stringify(hints)), false);
  assertEquals(containsIdNumber(JSON.stringify(ocrExtract)), false);
});

Deno.test('verification-ocr: license output has no raw ID numbers', async () => {
  const { hints, ocrExtract } = await runOcr('drivers_license', {
    full_name: 'Ada Okafor',
    license_number: 'LAG1234567',
    expiry: '2028-12-01',
  });

  assertEquals(hints.license_number, undefined);
  assertEquals(containsIdNumber(JSON.stringify(hints)), false);
  assertEquals(containsIdNumber(JSON.stringify(ocrExtract)), false);
});

Deno.test('verification-ocr: upstream with embedded digits in notes is redacted', async () => {
  const { hints } = await runOcr('nin', {
    full_name: 'Ada Okafor',
    id_number: '98765432109',
    note: 'Card serial 98765432109 attached',
  });

  assertEquals(hints.note?.includes('98765432109') ?? false, false);
  assertEquals(containsIdNumber(JSON.stringify(hints)), false);
});

Deno.test('verification-ocr: non-service caller is rejected', async () => {
  const res = await handleVerificationOcr(
    { verification_id: VERIFICATION_ID },
    {
      service: {
        from: () => {
          throw new Error('should not read documents');
        },
      } as never,
      caller: { serviceRole: false },
    },
  );
  assertEquals(res.status, 403);
});
