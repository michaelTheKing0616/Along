import { describe, expect, it } from 'vitest';
import { ADMIN_VERSION } from './index';

describe('admin-console bootstrap', () => {
  it('exports version', () => {
    expect(ADMIN_VERSION).toBe('0.0.0');
  });
});
