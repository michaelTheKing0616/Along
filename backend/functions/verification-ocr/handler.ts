import { z } from 'zod';
import {
  extractNormalizedId,
  redactOcrFields,
  containsIdNumber,
} from '../_shared/redact_ids.ts';
import { errorResponse, jsonResponse, requestId } from '../_shared/http.ts';
import { createServiceClient } from '../_shared/supabase.ts';
import type { SupabaseClient } from '@supabase/supabase-js';

export const verificationOcrRequestSchema = z.object({
  verification_id: z.string().uuid(),
});

export type VerificationOcrRequest = z.infer<typeof verificationOcrRequestSchema>;

type VerificationRow = {
  id: string;
  driver_id: string;
  document_type: string;
  storage_path: string | null;
  country_code: string;
};

export type OcrUpstreamResult = {
  fields: Record<string, string>;
  provider: string;
  provider_reference: string;
};

export type VerificationOcrDeps = {
  service: SupabaseClient;
  ocrUpstream?: (path: string, documentType: string) => Promise<OcrUpstreamResult>;
  computeHash?: (
    documentType: string,
    normalizedId: string,
  ) => Promise<string | null>;
};

async function defaultOcrUpstream(
  _path: string,
  documentType: string,
): Promise<OcrUpstreamResult> {
  if (documentType === 'nin') {
    return {
      fields: {
        full_name: 'Test Driver',
        id_number: '12345678901',
        dob: '1990-05-15',
      },
      provider: 'mock-verifyme',
      provider_reference: 'mock-ref-nin',
    };
  }

  if (documentType === 'drivers_license') {
    return {
      fields: {
        full_name: 'Test Driver',
        license_number: 'LAG1234567',
        expiry: '2028-12-01',
      },
      provider: 'mock-verifyme',
      provider_reference: 'mock-ref-license',
    };
  }

  return {
    fields: { full_name: 'Test Driver' },
    provider: 'mock-verifyme',
    provider_reference: 'mock-ref-generic',
  };
}

function byteaToBase64(value: unknown): string | null {
  if (value == null) return null;
  if (value instanceof Uint8Array) {
    return btoa(String.fromCharCode(...value));
  }
  if (typeof value === 'string') {
    const hex = value.startsWith('\\x') ? value.slice(2) : value;
    const bytes = hex.match(/.{1,2}/g)?.map((b) => parseInt(b, 16)) ?? [];
    if (bytes.length === 0) return null;
    return btoa(String.fromCharCode(...bytes));
  }
  return null;
}

async function defaultComputeHash(
  service: SupabaseClient,
  documentType: string,
  normalizedId: string,
): Promise<string | null> {
  const { data, error } = await service.rpc('compute_identity_hash', {
    p_document_type: documentType,
    p_normalized_id: normalizedId,
  });
  if (error || data == null) return null;
  return byteaToBase64(data);
}

export async function handleVerificationOcr(
  body: VerificationOcrRequest,
  deps: VerificationOcrDeps,
): Promise<Response> {
  const rid = requestId();
  const service = deps.service;

  const { data: row, error: fetchError } = await service
    .from('driver_verifications')
    .select('id, driver_id, document_type, storage_path, country_code')
    .eq('id', body.verification_id)
    .single();

  if (fetchError || !row) {
    return errorResponse('NOT_FOUND', 'Verification not found', 404, { request_id: rid });
  }

  const verification = row as VerificationRow;
  if (!verification.storage_path) {
    return errorResponse('VALIDATION', 'Missing storage path', 400, { request_id: rid });
  }

  const ocrUpstream = deps.ocrUpstream ?? defaultOcrUpstream;
  const upstream = await ocrUpstream(verification.storage_path, verification.document_type);

  const normalizedId = extractNormalizedId(verification.document_type, upstream.fields);
  const hints = redactOcrFields(upstream.fields);

  let idHashB64: string | null = null;
  if (normalizedId) {
    const computeHash = deps.computeHash
      ?? ((docType, normId) => defaultComputeHash(service, docType, normId));
    idHashB64 = await computeHash(verification.document_type, normalizedId);
  }

  const ocrExtract = {
    hints,
    provider: upstream.provider,
    ...(idHashB64 ? { id_hash: idHashB64 } : {}),
  };

  const serialized = JSON.stringify(ocrExtract);
  if (containsIdNumber(serialized)) {
    return errorResponse('VALIDATION', 'OCR output contained ID numbers', 500, {
      request_id: rid,
    });
  }

  const { error: updateError } = await service
    .from('driver_verifications')
    .update({
      ocr_extract: ocrExtract,
      provider: upstream.provider,
      provider_reference: upstream.provider_reference,
      updated_at: new Date().toISOString(),
    })
    .eq('id', body.verification_id);

  if (updateError) {
    return errorResponse('VALIDATION', updateError.message, 500, { request_id: rid });
  }

  return jsonResponse({
    data: {
      verification_id: body.verification_id,
      hints,
    },
    meta: { request_id: rid },
  });
}

export function handleVerificationOcrDefault(
  body: VerificationOcrRequest,
): Promise<Response> {
  return handleVerificationOcr(body, { service: createServiceClient() });
}
