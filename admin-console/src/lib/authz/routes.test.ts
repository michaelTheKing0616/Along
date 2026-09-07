import { describe, expect, it } from 'vitest';
import {
  getAllowedRolesForSegment,
  getConsoleSegment,
  isAgentPath,
  isPublicPath,
  ROUTE_ALLOWLIST,
} from './routes.js';

describe('authz routes', () => {
  it('marks auth paths as public', () => {
    expect(isPublicPath('/sign-in')).toBe(true);
    expect(isPublicPath('/mfa')).toBe(true);
    expect(isPublicPath('/p/W04TEST1')).toBe(true);
    expect(isPublicPath('/abuja/dashboard')).toBe(false);
    expect(isPublicPath('/agent')).toBe(false);
  });

  it('detects agent surface path', () => {
    expect(isAgentPath('/agent')).toBe(true);
    expect(isAgentPath('/abuja/dashboard')).toBe(false);
  });

  it('extracts console segment from city routes', () => {
    expect(getConsoleSegment('/abuja/dashboard')).toBe('dashboard');
    expect(getConsoleSegment('/abuja/finance/reports')).toBe('finance');
    expect(getConsoleSegment('/sign-in')).toBeNull();
  });

  it('restricts finance and admins routes', () => {
    expect(getAllowedRolesForSegment('finance')).toEqual(['superadmin', 'finance']);
    expect(getAllowedRolesForSegment('admins')).toEqual(['superadmin']);
    expect(ROUTE_ALLOWLIST.dashboard).toContain('verifier');
  });
});
