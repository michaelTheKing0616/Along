export type RevenueTab = 'placements' | 'api-keys' | 'accounts' | 'exports';

export type SponsoredPlacementRow = {
  id: string;
  context_type: string;
  target_reference: string;
  advertiser: string;
  content: Record<string, unknown>;
  active_from: string;
  active_to: string;
  impressions: number;
  taps: number;
};

export type ApiKeyRow = {
  id: string;
  owner_organization: string;
  scope: string[];
  rate_limit_per_min: number;
  created_at: string;
  revoked_at: string | null;
  total_calls: number;
};

export type RevenueCorporateAccountRow = {
  id: string;
  name: string;
  billing_email: string;
  status: string;
  monthly_budget: number | null;
  currency: string;
};

export type RevenueOperatorAccountRow = {
  id: string;
  name: string;
  type: string;
  subscription_tier: string;
  billing_status: string;
};

export type AnonymizedExportRow = {
  id: string;
  city_id: string;
  period_start: string;
  period_end: string;
  k_threshold: number;
  cells_emitted: number;
  cells_suppressed: number;
  trips_examined: number;
  created_at: string;
};

export type DeploymentOption = {
  id: string;
  tenant_name: string;
};
