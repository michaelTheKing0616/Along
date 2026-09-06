import { createClient } from '@/lib/supabase/server';

export type ActiveSettlementAgent = {
  id: string;
  business_name: string;
  city_id: string;
};

/** True when the session user is an active settlement agent (not admin_users). */
export async function getActiveSettlementAgent(): Promise<ActiveSettlementAgent | null> {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return null;

  const { data, error } = await supabase
    .from('settlement_agents')
    .select('id, business_name, city_id')
    .eq('profile_id', user.id)
    .eq('active', true)
    .maybeSingle();

  if (error || !data) return null;
  return data;
}
