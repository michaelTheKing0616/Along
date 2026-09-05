import { describe, expect, it } from 'vitest';
import { redactOcrExtract } from './redact-ocr';

describe('redactOcrExtract', () => {
  it('redacts raw identity fields from OCR extract', () => {
    const result = redactOcrExtract({
      hints: { full_name: 'Ada O.' },
      id_number: '12345678901',
      id_hash: 'abc123',
      nested: { nin: '98765432109', label: 'ok' },
    });

    expect(result).toEqual({
      hints: { full_name: 'Ada O.' },
      id_number: '[redacted]',
      id_hash: '[redacted]',
      nested: { nin: '[redacted]', label: 'ok' },
    });
  });

  it('returns empty object for null input', () => {
    expect(redactOcrExtract(null)).toEqual({});
  });
});
