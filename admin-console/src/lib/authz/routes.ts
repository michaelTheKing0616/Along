import type { AdminRole } from './roles';

/** Console route segment → roles allowed (UX allowlist; RLS is enforcement). */
export const ROUTE_ALLOWLIST: Record<string, readonly AdminRole[]> = {
  dashboard: [
    'superadmin',
    'ops_lead',
    'ops_agent',
    'verifier',
    'safety',
    'finance',
    'analyst',
    'city_admin',
  ],
  live: ['superadmin', 'ops_lead', 'ops_agent', 'safety'],
  verification: ['superadmin', 'ops_lead', 'ops_agent', 'verifier'],
  graph: ['superadmin', 'ops_lead', 'ops_agent', 'analyst'],
  corrections: ['superadmin', 'ops_lead', 'ops_agent'],
  field: ['superadmin', 'ops_lead', 'ops_agent'],
  deploy: ['superadmin', 'ops_lead'],
  config: ['superadmin', 'ops_lead'],
  integrity: ['superadmin', 'ops_lead', 'safety'],
  drivers: ['superadmin', 'ops_lead', 'safety', 'finance'],
  safety: ['superadmin', 'ops_lead', 'safety'],
  finance: ['superadmin', 'finance'],
  intelligence: ['superadmin', 'ops_lead', 'analyst'],
  analytics: ['superadmin', 'ops_lead', 'analyst'],
  audit: ['superadmin', 'ops_lead', 'finance'],
  admins: ['superadmin'],
  markets: ['superadmin', 'ops_lead'],
  revenue: ['superadmin', 'finance'],
  corporate: ['superadmin', 'finance', 'corporate_admin'],
  operator: ['superadmin', 'ops_lead', 'operator_viewer'],
};

const PUBLIC_PATHS = new Set(['/sign-in', '/mfa', '/unauthorized']);

/** Settlement-agent surface (P4-E-01) — not admin console. */
export const AGENT_PATH = '/agent';

/** W-04 anonymous web pay (P4-D-02) — no auth. */
export function isPayPath(pathname: string): boolean {
  return pathname === '/p' || pathname.startsWith('/p/');
}

/** Universal / App Link association files (P4-E-03) — no auth. */
export function isWellKnownPath(pathname: string): boolean {
  return pathname.startsWith('/.well-known/');
}

/** W-03 legal pages (P12-E-02) — no auth. */
export function isLegalPath(pathname: string): boolean {
  return pathname === '/legal' || pathname.startsWith('/legal/');
}

export function isAgentPath(pathname: string): boolean {
  return pathname === AGENT_PATH || pathname.startsWith(`${AGENT_PATH}/`);
}

export function isPublicPath(pathname: string): boolean {
  if (PUBLIC_PATHS.has(pathname)) return true;
  if (isPayPath(pathname)) return true;
  if (isWellKnownPath(pathname)) return true;
  if (isLegalPath(pathname)) return true;
  return false;
}

/** Extract console segment from /{city}/{segment}/... */
export function getConsoleSegment(pathname: string): string | null {
  const parts = pathname.split('/').filter(Boolean);
  if (parts.length < 2) return null;
  return parts[1] ?? null;
}

export function getAllowedRolesForSegment(segment: string): readonly AdminRole[] | null {
  return ROUTE_ALLOWLIST[segment] ?? null;
}

export async function isRoleAllowedForSegment(
  segment: string,
  roleCheck: (roles: readonly AdminRole[]) => Promise<boolean>
): Promise<boolean> {
  const allowed = getAllowedRolesForSegment(segment);
  if (!allowed) return true;
  return roleCheck(allowed);
}
