import { NextResponse } from 'next/server';
import { buildAssetLinks, WELL_KNOWN_CONTENT_TYPE } from '@/lib/universal-links/build';

export const dynamic = 'force-dynamic';

export function GET() {
  const body = buildAssetLinks();
  return new NextResponse(JSON.stringify(body), {
    status: 200,
    headers: {
      'Content-Type': WELL_KNOWN_CONTENT_TYPE,
      'Cache-Control': 'public, max-age=300',
    },
  });
}
