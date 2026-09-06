export interface MoneyAmount {
  amount: number;
  currency: string;
}

export interface QrResolveDriver {
  first_name?: string;
  plate?: string;
  mode?: string;
  accepts_digital: boolean;
  active: boolean;
}

export interface QrResolveContext {
  trip_id?: string;
  amount: MoneyAmount;
  label?: string;
  locked: boolean;
}

export interface QrResolvePayload {
  driver: QrResolveDriver;
  digital_enabled: boolean;
  context?: QrResolveContext | null;
  suggested_amounts: MoneyAmount[];
  currency: string;
  min_amount: MoneyAmount;
  warning?: string;
}

export interface PaymentInitiateResult {
  payment_id: string;
  authorization_url?: string;
  amount: number;
  commission_amount: number;
  driver_amount: number;
  receipt_token?: string;
  expires_at?: string;
}

export interface PaymentReceiptPayload {
  payment_id: string;
  amount: number;
  currency: string;
  commission_amount: number;
  driver_amount: number;
  driver_first_name?: string;
  plate?: string;
  status: string;
  confirmed_at?: string | null;
}
