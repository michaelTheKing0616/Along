import { describe, expect, it } from 'vitest';
import {
  CONVERSION_DIAGNOSTIC_NOTE,
  aggregateSummaries,
  formatRate,
} from './format';
import type { CorridorAnalyticsSummary } from './types';

const baseSummary = (overrides: Partial<CorridorAnalyticsSummary> = {}): CorridorAnalyticsSummary => ({
  searches: 10,
  ambient_views: 8,
  commits: 2,
  ambient_to_commit_rate: 0.25,
  ambient_to_commit_diagnostic: true,
  requests: 5,
  accept_rate: 0.8,
  completed_trips: 4,
  fulfilment_rate: 0.5,
  median_wait_s: 90,
  fare_discrepancy_rate: 0.1,
  avg_candidates_per_search: 2,
  avg_direct_candidates: 1,
  coverage_gap_count: 1,
  ...overrides,
});

describe('analytics format', () => {
  it('formatRate renders percentage for conversion metric', () => {
    expect(formatRate(0.25)).toBe('25.0%');
    expect(formatRate(null)).toBe('—');
  });

  it('aggregateSummaries computes city-wide ambient→commit rate', () => {
    const merged = aggregateSummaries([
      { summary: baseSummary({ ambient_views: 4, commits: 1, searches: 5 }) },
      { summary: baseSummary({ ambient_views: 6, commits: 3, searches: 5 }) },
    ]);
    expect(merged.ambient_views).toBe(10);
    expect(merged.commits).toBe(4);
    expect(merged.ambient_to_commit_rate).toBeCloseTo(0.4);
    expect(merged.ambient_to_commit_diagnostic).toBe(true);
  });

  it('conversion diagnostic note states display-only intent (FM13)', () => {
    expect(CONVERSION_DIAGNOSTIC_NOTE).toMatch(/diagnostic/i);
    expect(CONVERSION_DIAGNOSTIC_NOTE).toMatch(/does not trigger/i);
  });
});
