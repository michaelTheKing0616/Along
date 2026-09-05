import { NextResponse } from 'next/server';
import { VERIFICATION_SIGNED_URL_TTL_SECONDS } from '@/lib/verification/constants';
import { createClient, getSession } from '@/lib/supabase/server';

interface RouteParams {
  params: Promise<{ verificationId: string }>;
}

export async function GET(_request: Request, { params }: RouteParams) {
  const { verificationId } = await params;
  const session = await getSession();
  if (!session) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  const supabase = await createClient();

  const { data: logResult, error: logError } = await supabase.rpc('admin_log_view_document', {
    p_verification_id: verificationId,
  });

  if (logError) {
    const status =
      logError.message.includes('FORBIDDEN') || logError.code === '42501' ? 403 : 400;
    return NextResponse.json({ error: logError.message }, { status });
  }

  const storagePath = (logResult as { storage_path?: string | null } | null)?.storage_path;
  if (!storagePath) {
    return NextResponse.json(
      { error: 'Document storage path missing', logged: true },
      { status: 404 }
    );
  }

  const { data: signed, error: signError } = await supabase.storage
    .from('verification')
    .createSignedUrl(storagePath, VERIFICATION_SIGNED_URL_TTL_SECONDS);

  if (signError || !signed?.signedUrl) {
    return NextResponse.json(
      { error: signError?.message ?? 'Could not sign document URL', logged: true },
      { status: 502 }
    );
  }

  const watermarkAt = new Date().toISOString();
  return NextResponse.json({
    url: signed.signedUrl,
    expiresInSeconds: VERIFICATION_SIGNED_URL_TTL_SECONDS,
    watermark: {
      reviewerId: session.user.id,
      viewedAt: watermarkAt,
    },
    logged: true,
  });
}
