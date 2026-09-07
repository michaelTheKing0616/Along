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

export interface QrPaymentFinanceRow {
  id: string;
  driver_id: string;
  driver_code: string | null;
  amount: number;
  currency: string;
  source: string;
  status: string;
  trip_id: string | null;
  commission_amount: number;
  provider_fee: number | null;
  fee_bearer: string;
  created_at: string;
}

export interface FeeBearerReport {
  fee_bearer: string;
  payment_count: number;
  commission_total: number;
  provider_fee_total: number;
}

export interface StickerBatchDriver {
  id: string;
  driver_code: string;
  plate: string | null;
  pay_url: string;
}
