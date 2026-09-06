import { createClient } from '@supabase/supabase-js';
import type { Database } from '@along/contracts/db.types';
import type { PaymentReceiptPayload } from './web-pay-types';

export async function fetchPaymentReceiptServer(
  paymentId: string,
  receiptToken: string
): Promise<PaymentReceiptPayload> {
  const supabase = createClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  );

  const { data, error } = await supabase.rpc('payment_receipt_payload', {
    p_payment_id: paymentId,
    p_receipt_token: receiptToken,
  });

  if (error) {
    throw new Error(error.message);
  }

  return data as unknown as PaymentReceiptPayload;
}
