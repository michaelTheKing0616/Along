export interface SettlementRow {
  id: string;
  driver_id: string;
  driver_code: string | null;
  amount: number;
  currency: string;
  channel: string;
  status: string;
  created_at: string;
  confirmed_at: string | null;
}

export interface SettlementAgentRow {
  id: string;
  business_name: string;
  phone: string | null;
  active: boolean;
  created_at: string;
}

export interface PendingAdjustmentRow {
  id: string;
  driver_id: string;
  driver_code: string | null;
  amount: number;
  currency: string;
  memo: string;
  requested_by: string;
  requested_by_name: string | null;
  created_at: string;
}

export interface PayoutRow {
  id: string;
  driver_id: string;
  driver_code: string | null;
  amount: number;
  currency: string;
  status: string;
  provider_reference: string;
  created_at: string;
  confirmed_at: string | null;
}
