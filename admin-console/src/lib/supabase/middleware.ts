import { createServerClient } from '@supabase/ssr';
import { NextResponse, type NextRequest } from 'next/server';
import type { Database } from '@along/contracts/db.types';
import {
  getConsoleSegment,
  isAgentPath,
  isPublicPath,
  isRoleAllowedForSegment,
} from '@/lib/authz/routes';
import { MFA_REQUIRED_ROLES } from '@/lib/authz/roles';

export async function updateSession(request: NextRequest) {
  let supabaseResponse = NextResponse.next({ request });

  const supabase = createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll();
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value));
          supabaseResponse = NextResponse.next({ request });
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options)
          );
        },
      },
    }
  );

  const {
    data: { user },
  } = await supabase.auth.getUser();
  const pathname = request.nextUrl.pathname;

  if (isPublicPath(pathname)) {
    return supabaseResponse;
  }

  if (!user) {
    const url = request.nextUrl.clone();
    url.pathname = '/sign-in';
    url.searchParams.set('next', pathname);
    return NextResponse.redirect(url);
  }

  if (isAgentPath(pathname)) {
    return supabaseResponse;
  }

  const { data: isAdminUser } = await supabase.rpc('is_admin');
  if (!isAdminUser) {
    const url = request.nextUrl.clone();
    url.pathname = '/unauthorized';
    return NextResponse.redirect(url);
  }

  const { data: aalData } = await supabase.auth.mfa.getAuthenticatorAssuranceLevel();
  const currentAal = aalData?.currentLevel ?? 'aal1';

  const { data: needsMfa } = await supabase.rpc('has_admin_role', {
    roles: [...MFA_REQUIRED_ROLES],
  });

  if (needsMfa && currentAal !== 'aal2' && pathname !== '/mfa') {
    const url = request.nextUrl.clone();
    url.pathname = '/mfa';
    url.searchParams.set('next', pathname);
    return NextResponse.redirect(url);
  }

  const segment = getConsoleSegment(pathname);
  if (segment) {
    const allowed = await isRoleAllowedForSegment(segment, async (roles) => {
      const { data } = await supabase.rpc('has_admin_role', { roles: [...roles] });
      return Boolean(data);
    });

    if (!allowed) {
      const url = request.nextUrl.clone();
      url.pathname = '/unauthorized';
      return NextResponse.redirect(url);
    }
  }

  return supabaseResponse;
}
