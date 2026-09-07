import { execFileSync } from 'node:child_process';
import path from 'node:path';
import { describe, expect, it } from 'vitest';

describe('admin audit coverage grep (P6-D-04 AC)', () => {
  it('reports covered RPCs with Phase 7 intelligence RPCs OK', () => {
    const script = path.join(process.cwd(), 'scripts', 'check-admin-audit-coverage.mjs');
    const output = execFileSync('node', [script], { encoding: 'utf8' });

    expect(output).toContain('PASS: all non-gap admin write RPCs have audit coverage evidence');
    expect(output).toContain('OK  admin_review_candidate_park');
    expect(output).toContain('OK  admin_review_route_inference');
    expect(output).toContain('OK  admin_review_geometry_correction');
    expect(output).toContain('OK  admin_set_config');
    expect(output).toContain('OK  admin_invite_admin');
  });
});
