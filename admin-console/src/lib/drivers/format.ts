export function maskPhone(phone: string | null | undefined): string {
  if (!phone || phone.length < 8) return '—';
  return `${phone.slice(0, 4)}***${phone.slice(-4)}`;
}

export function standingLabel(standing: string): string {
  return standing.replace(/_/g, ' ');
}

export function formatMoney(amount: number | null, currency = 'NGN'): string {
  if (amount == null) return '—';
  const symbol = currency === 'NGN' ? '₦' : currency;
  return `${symbol}${amount.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
}
