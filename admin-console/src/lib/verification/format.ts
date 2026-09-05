export function maskPhoneE164(phone: string | null | undefined): string {
  if (!phone || phone.length < 6) return '—';
  return `${phone.slice(0, 4)}****${phone.slice(-3)}`;
}

export function queueAgeLabel(submittedAt: string): string {
  const ms = Date.now() - new Date(submittedAt).getTime();
  const hours = Math.floor(ms / (1000 * 60 * 60));
  if (hours < 1) {
    const mins = Math.max(1, Math.floor(ms / (1000 * 60)));
    return `${mins}m`;
  }
  if (hours < 48) return `${hours}h`;
  const days = Math.floor(hours / 24);
  return `${days}d`;
}

export function sortVerificationQueue<T extends { status: string; submitted_at: string }>(
  rows: T[]
): T[] {
  return [...rows].sort((a, b) => {
    const aPending = a.status === 'pending' ? 0 : 1;
    const bPending = b.status === 'pending' ? 0 : 1;
    if (aPending !== bPending) return aPending - bPending;
    return new Date(a.submitted_at).getTime() - new Date(b.submitted_at).getTime();
  });
}
