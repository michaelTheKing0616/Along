import { createClient } from '@/lib/supabase/server';
import { redirect } from 'next/navigation';

export default async function HomePage() {
  const supabase = await createClient();
  const { data } = await supabase
    .from('cities')
    .select('slug')
    .in('status', ['alpha', 'beta', 'live'])
    .order('name')
    .limit(1)
    .maybeSingle();

  redirect(`/${data?.slug ?? 'abuja'}/dashboard`);
}
