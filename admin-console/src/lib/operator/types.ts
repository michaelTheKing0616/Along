export type OperatorOverview = {
  operator_account_id: string;
  from: string;
  to: string;
  driver_count: number;
  trips_completed: number;
  fare_discrepancy_rate: number | null;
  aggregate_only: boolean;
  online_total: number;
  online_at_park: number;
  online_roaming: number;
  trips_per_day: number | null;
};

export type OperatorAccountRow = {
  id: string;
  name: string;
  type: string;
  subscription_tier: string;
  billing_status: string;
};
