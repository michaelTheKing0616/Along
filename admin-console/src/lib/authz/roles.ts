import type { Database } from '@along/contracts/db.types';

export type AdminRole = Database['public']['Enums']['admin_role'];

export const ADMIN_ROLES: readonly AdminRole[] = [
  'superadmin',
  'ops_lead',
  'ops_agent',
  'verifier',
  'safety',
  'finance',
  'analyst',
  'city_admin',
  'operator_viewer',
  'corporate_admin',
] as const;

/** Roles that must complete TOTP (aal2) before console access — doc 08 §1. */
export const MFA_REQUIRED_ROLES: readonly AdminRole[] = [
  'superadmin',
  'finance',
  'safety',
  'ops_lead',
] as const;

export function roleRequiresMfa(role: AdminRole): boolean {
  return (MFA_REQUIRED_ROLES as readonly string[]).includes(role);
}
