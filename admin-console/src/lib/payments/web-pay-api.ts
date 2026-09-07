import type {
  PaymentInitiateResult,
  PaymentReceiptPayload,
  QrResolvePayload,
} from './web-pay-types';

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const ANON_KEY = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

function functionsUrl(path: string): string {
  return `${SUPABASE_URL}/functions/v1/${path}`;
}

async function parseEnvelope<T>(res: Response): Promise<T> {
  const body = (await res.json()) as {
    data?: T;
    error?: { code?: string; message?: string };
  };
  if (!res.ok) {
    const message = body.error?.message ?? `Request failed (${res.status})`;
    throw new Error(message);
  }
  if (body.data === undefined) {
    throw new Error('Empty response');
  }
  return body.data;
}

export async function fetchQrResolve(
  driverCode: string,
  token?: string | null
): Promise<QrResolvePayload> {
  const qs = token ? `?t=${encodeURIComponent(token)}` : '';
  const res = await fetch(functionsUrl(`qr/resolve/${encodeURIComponent(driverCode)}${qs}`), {
    headers: { apikey: ANON_KEY },
    next: { revalidate: 30 },
  });
  return parseEnvelope<QrResolvePayload>(res);
}

export async function initiateWebPayment(input: {
  driverCode: string;
  amount: number;
  token?: string | null;
  payerPhone?: string | null;
}): Promise<PaymentInitiateResult> {
  const res = await fetch(functionsUrl('payments/initiate'), {
    method: 'POST',
    headers: {
      apikey: ANON_KEY,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      driver_code: input.driverCode,
      amount: input.amount,
      channel: 'web',
      token: input.token ?? undefined,
      payer_phone: input.payerPhone ?? undefined,
    }),
  });
  return parseEnvelope<PaymentInitiateResult>(res);
}

export async function fetchPaymentReceipt(
  paymentId: string,
  receiptToken: string
): Promise<PaymentReceiptPayload> {
  const qs = new URLSearchParams({ receipt_token: receiptToken });
  const res = await fetch(
    functionsUrl(`payments/receipt/${encodeURIComponent(paymentId)}?${qs}`),
    { headers: { apikey: ANON_KEY } }
  );
  return parseEnvelope<PaymentReceiptPayload>(res);
}

export function formatMoneyAmount(
  amount: number,
  currency: string,
  currencySymbol?: string,
): string {
  const symbol =
    currencySymbol ?? (currency === 'NGN' ? '₦' : `${currency} `);
  return `${symbol}${amount.toLocaleString(undefined, {
    minimumFractionDigits: 0,
    maximumFractionDigits: 2,
  })}`;
}

/** @deprecated Use formatMoneyAmount with currency from resolve/receipt payload */
export function formatNaira(amount: number): string {
  return formatMoneyAmount(amount, 'NGN');
}

export function modeLabel(mode: string | undefined): string {
  switch (mode) {
    case 'keke':
      return 'Keke';
    case 'okada':
      return 'Okada';
    case 'minibus':
      return 'Minibus';
    default:
      return 'Along taxi';
  }
}
