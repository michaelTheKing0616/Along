import { createClient } from '@/lib/supabase/server';

export type CityRow = {
  id: string;
  name: string;
  slug: string;
  status: string;
  country_code: string;
};

export async function getCityBySlug(slug: string): Promise<CityRow | null> {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from('cities')
    .select('id, name, slug, status, country_code')
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
