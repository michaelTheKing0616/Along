import { describe, expect, it } from 'vitest';
import { formatAgeSeconds, slaTierForOpenSos } from './format';

describe('safety format helpers', () => {
  it('formats sub-minute ages', () => {
    expect(formatAgeSeconds(45)).toBe('45s');
  });

  it('escalates SLA tiers from config thresholds', () => {
    const sla = { ackSlaS: 60, escalateSlaS: 180 };
    expect(slaTierForOpenSos(30, sla)).toBe('normal');
    expect(slaTierForOpenSos(60, sla)).toBe('warning');
    expect(slaTierForOpenSos(180, sla)).toBe('critical');
  });
});
