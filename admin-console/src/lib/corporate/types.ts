export type CorporateTab = 'overview' | 'roster' | 'policies' | 'history' | 'billing';

export type CorporateOverview = {
  corporate_account_id: string;
  account_name: string;
  currency: string;
  monthly_budget: number | null;
  subsidy_used_mtd: number;
  enrolled_staff: number;
  active_staff_trips: number;
  live_trips: CorporateLiveTrip[];
};

export type CorporateLiveTrip = {
  trip_id: string;
  employee_ref: string | null;
  department: string | null;
  status: string;
  mode_code: string;
  fare_shown: number;
  requested_at: string;
};

export type CorporateMemberRow = {
  rider_id: string;
  employee_ref: string | null;
  department: string | null;
  default_policy_id: string | null;
  active: boolean;
  since: string;
  phone_e164: string | null;
  display_name: string | null;
  policy_name: string | null;
};

export type CorporatePolicyRow = {
  id: string;
  name: string;
  subsidy_pct: number;
  max_per_trip: number | null;
  allowed_hours: Record<string, unknown> | null;
  active: boolean;
};

export type CorporateAllocationRow = {
  id: string;
  trip_id: string;
  subsidized_amount: number;
  created_at: string;
  employee_ref: string | null;
  department: string | null;
  mode_code: string | null;
  fare_shown: number | null;
  policy_name: string | null;
};

export type CorporateInvoiceRow = {
  id: string;
  period_start: string;
  period_end: string;
  total: number;
  currency: string;
  status: string;
  generated_at: string;
};
