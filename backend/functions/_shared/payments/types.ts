export type SettlementChannel = 'paystack_transfer' | 'paystack_ussd' | 'paystack_card';

export type SettlementInitiateParams = {
  settlementId: string;
  amount: number;
  currency: string;
  channel: SettlementChannel;
  driverId: string;
  driverEmail?: string;
  callbackUrl?: string;
};

export type SettlementInitiateResult = {
  providerReference: string;
  authorizationUrl?: string;
  ussdCode?: string;
  bankAccount?: Record<string, unknown>;
  expiresAt: string;
};

export type PaymentMethodPref = 'card' | 'bank_transfer' | 'ussd';

export type TripPaymentInitiateParams = {
  paymentId: string;
  amount: number;
  commissionAmount: number;
  currency: string;
  method: PaymentMethodPref;
  riderEmail?: string;
  driverSubaccountCode: string;
  feeBearer: 'account' | 'subaccount';
  callbackUrl?: string;
};

export type TripPaymentInitiateResult = {
  providerReference: string;
  authorizationUrl?: string;
  ussdCode?: string;
  bankAccount?: Record<string, unknown>;
  expiresAt: string;
};

export type PayoutTransferParams = {
  payoutId: string;
  amount: number;
  currency: string;
  recipientCode: string;
  reference: string;
  reason?: string;
};

export type PayoutTransferResult = {
  providerReference: string;
  transferCode?: string;
  status: 'pending' | 'success' | 'failed';
};

export interface PaymentProvider {
  initiateSettlement(params: SettlementInitiateParams): Promise<SettlementInitiateResult>;
  initiateTripPayment(params: TripPaymentInitiateParams): Promise<TripPaymentInitiateResult>;
  initiatePayoutTransfer(params: PayoutTransferParams): Promise<PayoutTransferResult>;
}
