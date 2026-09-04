import { createAdminClient } from '@/lib/supabase/admin';

export type CityRow = {
  id: string;
  name: string;
  slug: string;
  status: string;
};

export async function getCityBySlug(slug: string): Promise<CityRow | null> {
  // cities lacks SELECT grant for authenticated (P0-A-09); admin console resolves city server-side.
  const supabase = createAdminClient();
  const { data, error } = await supabase
    .from('cities')
    .select('id, name, slug, status')
    .eq('slug', slug)
    .maybeSingle();

  if (error) {
    console.error('[getCityBySlug]', slug, error.message);
    return null;
  }
  if (!data) {
    console.error('[getCityBySlug] no row for slug', slug);
    return null;
  }
  return data;
}
