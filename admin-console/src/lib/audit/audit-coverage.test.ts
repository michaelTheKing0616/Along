import { execFileSync } from 'node:child_process';
import path from 'node:path';
import { describe, expect, it } from 'vitest';

describe('admin audit coverage grep (P6-D-04 AC)', () => {
  it('reports covered RPCs and explicit P6-A-01 gaps', () => {
    const script = path.join(process.cwd(), 'scripts', 'check-admin-audit-coverage.mjs');
    const output = execFileSync('node', [script], { encoding: 'utf8' });

    expect(output).toContain('PASS: all non-gap admin write RPCs have audit coverage evidence');
    expect(output).toContain('GAP admin_review_flag');
    expect(output).toContain('GAP admin_transition_standing');
    expect(output).toContain('OK  admin_set_config');
    expect(output).toContain('OK  admin_invite_admin');
  });
});
