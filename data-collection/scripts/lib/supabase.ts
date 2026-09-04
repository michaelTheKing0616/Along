/**
 * Supabase service-role REST client for field ingestion (doc 13 §3).
 */

const DEFAULT_URL = 'http://127.0.0.1:54321';
const DEFAULT_SERVICE_KEY =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU';

export interface SupabaseConfig {
  url: string;
  serviceRoleKey: string;
}

export function loadSupabaseConfig(): SupabaseConfig {
  return {
    url: (process.env.SUPABASE_URL ?? DEFAULT_URL).replace(/\/$/, ''),
    serviceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY ?? DEFAULT_SERVICE_KEY,
  };
}

function headers(config: SupabaseConfig, extra?: Record<string, string>): Record<string, string> {
  return {
    apikey: config.serviceRoleKey,
    Authorization: `Bearer ${config.serviceRoleKey}`,
    'Content-Type': 'application/json',
    ...extra,
  };
}

export async function supabaseGet<T>(
  config: SupabaseConfig,
  path: string,
  query?: Record<string, string>
): Promise<T> {
  const qs = query ? `?${new URLSearchParams(query).toString()}` : '';
  const res = await fetch(`${config.url}/rest/v1/${path}${qs}`, {
    headers: headers(config),
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`GET ${path} failed (${res.status}): ${body}`);
  }
  return (await res.json()) as T;
}

export async function supabaseInsert<T extends Record<string, unknown>>(
  config: SupabaseConfig,
  table: string,
  row: T
): Promise<T & { id: string }> {
  const res = await fetch(`${config.url}/rest/v1/${table}`, {
    method: 'POST',
    headers: headers(config, { Prefer: 'return=representation' }),
    body: JSON.stringify(row),
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`INSERT ${table} failed (${res.status}): ${body}`);
  }
  const rows = (await res.json()) as Array<T & { id: string }>;
  return rows[0]!;
}

export async function supabaseRpc<T>(
  config: SupabaseConfig,
  fn: string,
  args: Record<string, unknown>
): Promise<T> {
  const res = await fetch(`${config.url}/rest/v1/rpc/${fn}`, {
    method: 'POST',
    headers: headers(config),
    body: JSON.stringify(args),
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`RPC ${fn} failed (${res.status}): ${body}`);
  }
  const text = await res.text();
  if (!text) return undefined as T;
  return JSON.parse(text) as T;
}

export interface CityRow {
  id: string;
  slug: string;
  name: string;
}

export interface CorridorRow {
  id: string;
  name: string;
  slug: string;
  city_id: string;
}

export interface ModeRow {
  code: string;
  label: string;
}

export interface ParkRow {
  id: string;
  name: string;
  city_id: string;
}

export interface FieldSubmissionRow {
  id: string;
  entity_type: string;
  entity_key: string;
  submission_uid: string;
  status: string;
}

export interface FieldReconciliationRow {
  id: string;
  entity_type: string;
  entity_key: string;
  status: string;
  variance: Record<string, unknown> | null;
  submission_a: string;
  submission_b: string | null;
}

export async function fetchReconciliation(
  config: SupabaseConfig,
  entityKey: string
): Promise<FieldReconciliationRow | null> {
  const rows = await supabaseGet<FieldReconciliationRow[]>(
    config,
    'field_reconciliations',
    {
      select: 'id,entity_type,entity_key,status,variance,submission_a,submission_b',
      entity_key: `eq.${entityKey}`,
      order: 'created_at.desc',
      limit: '1',
    }
  );
  return rows[0] ?? null;
}
