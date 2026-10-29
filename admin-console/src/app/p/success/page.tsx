import { formatNaira } from "@/lib/payments/web-pay-api";
import { fetchPaymentReceiptServer } from "@/lib/payments/receipt-server";
import "../pay.css";

interface PageProps {
  searchParams: Promise<{ payment_id?: string; receipt_token?: string }>;
}

export default async function PaySuccessPage({ searchParams }: PageProps) {
  const { payment_id: paymentId, receipt_token: receiptToken } =
    await searchParams;

  if (!paymentId || !receiptToken) {
    return (
      <main className="w04-main w04-state" data-testid="w04-success-error">
        <h1>Receipt unavailable</h1>
        <p>Receipt link is incomplete.</p>
      </main>
    );
  }

  let receipt;
  let error: string | null = null;
  try {
    receipt = await fetchPaymentReceiptServer(paymentId, receiptToken);
  } catch (err) {
    error = err instanceof Error ? err.message : "Could not load receipt";
  }

  if (error || !receipt) {
    return (
      <main className="w04-main w04-state" data-testid="w04-success-error">
        <h1>Receipt unavailable</h1>
        <p>{error ?? "Could not load receipt"}</p>
      </main>
    );
  }

  return (
    <main className="w04-main" data-testid="w04-success">
      <p className="w04-brand">Payment received</p>
      <div className="w04-paid-mark" aria-hidden="true">
        ✓
      </div>
      <h1 className="w04-paid-amount">{formatNaira(receipt.amount)}</h1>
      <p className="w04-driver">
        Paid to {receipt.driver_first_name ?? "driver"}
        {receipt.plate ? ` · ${receipt.plate}` : ""}
      </p>

      <div className="w04-receipt">
        <div className="w04-receipt-row">
          <span>To driver</span>
          <span>{formatNaira(receipt.driver_amount)}</span>
        </div>
        <div className="w04-receipt-row">
          <span>Along fee</span>
          <span>{formatNaira(receipt.commission_amount)}</span>
        </div>
      </div>

      <footer className="w04-footer">
        <a href="https://along.ng" data-testid="w04-get-along">
          Get Along for fares and routes
        </a>
      </footer>
    </main>
  );
}
