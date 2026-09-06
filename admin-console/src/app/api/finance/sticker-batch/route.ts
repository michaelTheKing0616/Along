import { NextResponse } from 'next/server';
import { renderStickerBatchPdf } from '@/lib/finance/sticker-pdf';
import { createClient } from '@/lib/supabase/server';

export const runtime = 'nodejs';

interface StickerBatchBody {
  cityId?: string;
  driverIds?: string[];
}

export async function POST(request: Request) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  const { data: isFinance } = await supabase.rpc('has_admin_role', {
    roles: ['superadmin', 'finance'],
  });
  if (!isFinance) {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
  }

  let body: StickerBatchBody;
  try {
    body = (await request.json()) as StickerBatchBody;
  } catch {
    return NextResponse.json({ error: 'Invalid JSON' }, { status: 400 });
  }

  const cityId = body.cityId;
  const driverIds = body.driverIds ?? [];
  if (!cityId || driverIds.length === 0) {
    return NextResponse.json({ error: 'cityId and driverIds required' }, { status: 400 });
  }

  const { data: driverRows, error } = await supabase
    .from('drivers')
    .select(
      `
      id,
      driver_code,
      city_id,
      driver_vehicles (
        active,
        vehicles ( plate_number )
      )
    `
    )
    .eq('city_id', cityId)
    .in('id', driverIds);

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 400 });
  }

  const origin =
    process.env.NEXT_PUBLIC_PAY_ORIGIN ??
    process.env.NEXT_PUBLIC_SITE_URL ??
    'http://127.0.0.1:3000';

  const labels = (driverRows ?? [])
    .filter((d) => d.driver_code)
    .map((d) => {
      const dv = d.driver_vehicles as Array<{
        active: boolean;
        vehicles: { plate_number: string } | null;
      }>;
      const activeVehicle = dv?.find((v) => v.active)?.vehicles;
      return {
        id: d.id,
        driver_code: d.driver_code as string,
        plate: activeVehicle?.plate_number ?? null,
        pay_url: `${origin.replace(/\/$/, '')}/p/${d.driver_code}`,
      };
    });

  if (labels.length === 0) {
    return NextResponse.json({ error: 'No drivers with codes found' }, { status: 404 });
  }

  const pdf = await renderStickerBatchPdf(labels, origin);

  return new NextResponse(pdf, {
    status: 200,
    headers: {
      'Content-Type': 'application/pdf',
      'Content-Disposition': 'attachment; filename="along-sticker-batch-preview.pdf"',
      'Cache-Control': 'no-store',
    },
  });
}
