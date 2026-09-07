import { createClient } from '@supabase/supabase-js';
import type { Database } from '@along/contracts/db.types';
import type { QrResolvePayload } from './web-pay-types';

export async function resolveQrDriverServer(
  driverCode: string,
  token?: string | null
): Promise<QrResolvePayload> {
  const supabase = createClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  );

  const { data, error } = await supabase.rpc('resolve_qr_driver', {
    p_driver_code: driverCode,
    p_rider_id: undefined,
    p_token: token ?? undefined,
  });

  if (error) {
    throw new Error(error.message);
  }

  return data as unknown as QrResolvePayload;
}
