import { describe, expect, it } from 'vitest';
import { formatEtaMinutes, modeLabel, sharedEtaLabel } from '@/lib/safety/shared-trip-server';

describe('shared trip helpers', () => {
  it('formatEtaMinutes rounds up to at least 1 minute', () => {
    expect(formatEtaMinutes(30)).toBe('1 min');
    expect(formatEtaMinutes(420)).toBe('7 min');
  });

  it('modeLabel prefers provided label', () => {
    expect(modeLabel('keke', 'Keke')).toBe('Keke');
    expect(modeLabel('okada')).toBe('okada');
  });

  it('sharedEtaLabel uses the payload, including Calculating', () => {
    expect(
      sharedEtaLabel({
        eta_s: 0,
        eta: { status: 'calculating', trip: null, pickup: null },
      }),
    ).toBe('Calculating…');
    expect(
      sharedEtaLabel({
        eta_s: 480,
        eta: { status: 'ready', trip: { label: '8 min' }, pickup: null },
      }),
    ).toBe('8 min');
    expect(sharedEtaLabel({ eta_s: 420 })).toBe('7 min');
  });
});
