import type { FareCorrectionQueueRow } from './types';

export function formatMoney(amount: number | null, currency: string): string {
  if (amount == null) return '—';
  return `${currency} ${amount.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
}

export function formatDeltaPct(delta: number | null): string {
  if (delta == null) return '—';
  const sign = delta > 0 ? '+' : '';
  return `${sign}${delta.toFixed(1)}%`;
}

export function queueAgeLabel(iso: string): string {
  const ms = Date.now() - new Date(iso).getTime();
  const mins = Math.floor(ms / 60_000);
  if (mins < 60) return `${mins}m`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 48) return `${hrs}h`;
  return `${Math.floor(hrs / 24)}d`;
}

export function sortCorrectionQueue(rows: FareCorrectionQueueRow[]): FareCorrectionQueueRow[] {
  const rank = (s: FareCorrectionQueueRow['status']) => (s === 'pending' ? 0 : 1);
  return [...rows].sort((a, b) => {
    const rs = rank(a.status) - rank(b.status);
    if (rs !== 0) return rs;
    return new Date(a.created_at).getTime() - new Date(b.created_at).getTime();
  });
}
