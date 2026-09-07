import { describe, expect, it } from 'vitest';
import { changedAuditKeys, formatAuditJson } from '@/lib/audit/diff';

describe('audit diff helpers', () => {
  it('formats null as em dash', () => {
    expect(formatAuditJson(null)).toBe('—');
  });

  it('lists changed keys between before and after payloads', () => {
    expect(
      changedAuditKeys(
        { value: 60, scope_type: 'global' },
        { value: 80, scope_type: 'global', reason: 'ops tweak' }
      )
    ).toEqual(['reason', 'value']);
  });
});
