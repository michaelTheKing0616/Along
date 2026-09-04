import { describe, expect, it } from 'vitest';
import { JOBS_VERSION } from './index.js';

describe('jobs bootstrap', () => {
  it('exports version', () => {
    expect(JOBS_VERSION).toBe('0.0.0');
  });
});
