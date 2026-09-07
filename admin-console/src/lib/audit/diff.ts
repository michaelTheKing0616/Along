export function formatAuditJson(value: unknown): string {
  if (value == null) return '—';
  try {
    return JSON.stringify(value, null, 2);
  } catch {
    return String(value);
  }
}

/** Keys present in after but changed vs before (shallow compare on shared keys). */
export function changedAuditKeys(
  before: Record<string, unknown> | null,
  after: Record<string, unknown> | null
): string[] {
  if (!before && !after) return [];
  if (!before) return Object.keys(after ?? {});
  if (!after) return Object.keys(before);

  const keys = new Set([...Object.keys(before), ...Object.keys(after)]);
  const changed: string[] = [];
  for (const key of keys) {
    const b = before[key];
    const a = after[key];
    if (JSON.stringify(b) !== JSON.stringify(a)) changed.push(key);
  }
  return changed.sort();
}
