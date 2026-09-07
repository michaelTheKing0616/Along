export type AdminUserRow = {
  id: string;
  email: string | null;
  display_name: string | null;
  role: string;
  deployment_id: string | null;
  deployment_name: string | null;
  city_scope: string[];
  disabled_at: string | null;
  created_at: string;
  totp_enrolled: boolean;
  totp_required: boolean;
};

export type AdminListResponse = {
  rows: AdminUserRow[];
  next_cursor: string | null;
};

export type DeploymentOption = {
  id: string;
  tenant_name: string;
};

export type CityScopeOption = {
  id: string;
  name: string;
  slug: string;
};
