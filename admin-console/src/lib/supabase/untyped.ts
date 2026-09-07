import type { SupabaseClient } from '@supabase/supabase-js';
import type { Database } from '@along/contracts/db.types';

type AlongSupabase = SupabaseClient<Database>;

/** Tables/RPCs not yet in generated db.types (Phase 8). */
export function rpcUntyped(
  supabase: AlongSupabase,
  fn: string,
  args: Record<string, unknown> = {}
) {
  return supabase.rpc(fn as never, args as never);
}

export function fromUntyped(supabase: AlongSupabase, table: string) {
  return supabase.from(table as never);
}
