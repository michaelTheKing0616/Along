import type {
  PaymentProvider,
  PayoutTransferParams,
  PayoutTransferResult,
  SettlementInitiateParams,
  SettlementInitiateResult,
  TripPaymentInitiateParams,
  TripPaymentInitiateResult,
} from './types.ts';

export type PaystackFetch = typeof fetch;

type PaystackInitResponse = {
  status?: boolean;
  message?: string;
  data?: {
    reference?: string;
    authorization_url?: string;
    ussd_code?: string;
    account_number?: string;
    account_name?: string;
    bank?: { name?: string };
  };
};

type PaystackTransferResponse = {
  status?: boolean;
  message?: string;
  data?: {
    reference?: string;
    transfer_code?: string;
    status?: string;
  };
};

function channelToPaystack(channel: SettlementInitiateParams['channel']): string {
  switch (channel) {
    case 'paystack_card':
      return 'card';
    case 'paystack_ussd':
      return 'ussd';
    case 'paystack_transfer':
      return 'bank_transfer';
  }
}

function paystackChannels(method: TripPaymentInitiateParams['method']): string[] {
  switch (method) {
    case 'card':
      return ['card'];
    case 'ussd':
      return ['ussd'];
    case 'bank_transfer':
      return ['bank_transfer'];
  }
}

export function createPaystackProvider(
  secretKey: string,
  fetchImpl: PaystackFetch = fetch,
): PaymentProvider {
  return {
    async initiateTripPayment(
      params: TripPaymentInitiateParams,
    ): Promise<TripPaymentInitiateResult> {
      const amountKobo = Math.round(params.amount * 100);
      const commissionKobo = Math.round(params.commissionAmount * 100);
      const reference = `pay_${params.paymentId.replace(/-/g, '').slice(0, 20)}_${Date.now()}`;

      const res = await fetchImpl('https://api.paystack.co/transaction/initialize', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${secretKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          email: params.riderEmail ?? `${params.paymentId}@riders.along.ng`,
          amount: amountKobo,
          currency: params.currency,
          reference,
          subaccount: params.driverSubaccountCode,
          transaction_charge: commissionKobo,
          bearer: params.feeBearer,
          channels: paystackChannels(params.method),
          callback_url: params.callbackUrl,
          metadata: {
            payment_id: params.paymentId,
          },
        }),
      });

      const payload = (await res.json()) as PaystackInitResponse;
      if (!res.ok || !payload.status || !payload.data?.reference) {
        throw new Error(payload.message ?? 'Paystack initialize failed');
      }

      const expiresAt = new Date(Date.now() + 30 * 60 * 1000).toISOString();
      const data = payload.data;

      const result: TripPaymentInitiateResult = {
        providerReference: data.reference!,
        expiresAt,
      };

      if (params.method === 'card') {
        result.authorizationUrl = data.authorization_url;
      } else if (params.method === 'ussd') {
        result.ussdCode = data.ussd_code;
      } else if (params.method === 'bank_transfer') {
        result.bankAccount = {
          account_number: data.account_number,
          account_name: data.account_name,
          bank_name: data.bank?.name,
        };
      }

      return result;
    },

    async initiateSettlement(params: SettlementInitiateParams): Promise<SettlementInitiateResult> {
      const amountKobo = Math.round(params.amount * 100);
      const reference = `stl_${params.settlementId.replace(/-/g, '').slice(0, 20)}_${Date.now()}`;

      const res = await fetchImpl('https://api.paystack.co/transaction/initialize', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${secretKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          email: params.driverEmail ?? `${params.driverId}@drivers.along.ng`,
          amount: amountKobo,
          currency: params.currency,
          reference,
          channels: [channelToPaystack(params.channel)],
          callback_url: params.callbackUrl,
          metadata: {
            settlement_id: params.settlementId,
            driver_id: params.driverId,
          },
        }),
      });

      const payload = (await res.json()) as PaystackInitResponse;
      if (!res.ok || !payload.status || !payload.data?.reference) {
        throw new Error(payload.message ?? 'Paystack initialize failed');
      }

      const expiresAt = new Date(Date.now() + 30 * 60 * 1000).toISOString();
      const data = payload.data;

      const result: SettlementInitiateResult = {
        providerReference: data.reference!,
        expiresAt,
      };

      if (params.channel === 'paystack_card') {
        result.authorizationUrl = data.authorization_url;
      } else if (params.channel === 'paystack_ussd') {
        result.ussdCode = data.ussd_code;
      } else if (params.channel === 'paystack_transfer') {
        result.bankAccount = {
          account_number: data.account_number,
          account_name: data.account_name,
          bank_name: data.bank?.name,
        };
      }

      return result;
    },

    async initiatePayoutTransfer(
      params: PayoutTransferParams,
    ): Promise<PayoutTransferResult> {
      const amountKobo = Math.round(params.amount * 100);

      const res = await fetchImpl('https://api.paystack.co/transfer', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${secretKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          source: 'balance',
          amount: amountKobo,
          currency: params.currency,
          reference: params.reference,
          recipient: params.recipientCode,
          reason: params.reason ?? 'Along driver balance payout',
          metadata: {
            payout_id: params.payoutId,
          },
        }),
      });

      const payload = (await res.json()) as PaystackTransferResponse;
      if (!res.ok || !payload.status || !payload.data?.reference) {
        throw new Error(payload.message ?? 'Paystack transfer failed');
      }

      const transferStatus = payload.data.status === 'success' ? 'success' : 'pending';

      return {
        providerReference: payload.data.reference ?? params.reference,
        transferCode: payload.data.transfer_code,
        status: transferStatus,
      };
    },
  };
}
