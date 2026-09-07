import { describe, expect, it } from 'vitest';
import { formatEtaMinutes, modeLabel } from '@/lib/safety/shared-trip-server';

describe('shared trip helpers', () => {
  it('formatEtaMinutes rounds up to at least 1 minute', () => {
    expect(formatEtaMinutes(30)).toBe('1 min');
    expect(formatEtaMinutes(420)).toBe('7 min');
  });

  it('modeLabel prefers provided label', () => {
    expect(modeLabel('keke', 'Keke')).toBe('Keke');
    expect(modeLabel('okada')).toBe('okada');
  });
});
