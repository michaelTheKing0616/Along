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

export interface PaymentProvider {
  initiateSettlement(params: SettlementInitiateParams): Promise<SettlementInitiateResult>;
}
