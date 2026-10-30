/** Turns a snake_case status or role code into readable text: "false_alarm" → "false alarm". */
export function humanize(value: string | null | undefined): string {
  if (value == null) return '—';
  return value.replace(/_/g, ' ');
}

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** Shortens a UUID to its first 8 characters for display; other identifiers pass through. */
export function shortId(value: string | null | undefined): string {
  if (!value) return '—';
  return UUID.test(value) ? value.slice(0, 8) : value;
}
