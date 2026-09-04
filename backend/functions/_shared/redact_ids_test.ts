import { assertEquals } from 'jsr:@std/assert@1';
import {
  containsIdNumber,
  extractNormalizedId,
  redactIdNumbers,
  redactOcrFields,
} from './redact_ids.ts';

Deno.test('redact_ids: NIN pattern removed from text', () => {
  const input = 'Name: Ada Okafor, NIN: 12345678901, DOB: 1990-01-01';
  const redacted = redactIdNumbers(input);
  assertEquals(redacted.includes('12345678901'), false);
  assertEquals(redacted.includes('[REDACTED]'), true);
  assertEquals(containsIdNumber(redacted), false);
});

Deno.test('redact_ids: license pattern removed from text', () => {
  const input = 'License ABC1234567 issued Lagos';
  const redacted = redactIdNumbers(input);
  assertEquals(redacted.includes('ABC1234567'), false);
  assertEquals(containsIdNumber(redacted), false);
});

Deno.test('redact_ids: OCR fields drop id keys and redact values', () => {
  const hints = redactOcrFields({
    full_name: 'Ada Okafor',
    id_number: '12345678901',
    nin: '12345678901',
    dob: '1990-01-01',
    note: 'Ref 12345678901',
  });

  assertEquals(hints.id_number, undefined);
  assertEquals(hints.nin, undefined);
  assertEquals(hints.full_name, 'Ada Okafor');
  assertEquals(hints.note.includes('12345678901'), false);
  assertEquals(containsIdNumber(JSON.stringify(hints)), false);
});

Deno.test('redact_ids: extractNormalizedId for NIN', () => {
  assertEquals(
    extractNormalizedId('nin', { id_number: '1234-567-8901' }),
    '12345678901',
  );
});
