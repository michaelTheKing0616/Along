'use client';

import { Suspense } from 'react';
import SignInForm from './sign-in-form';

export default function SignInPage() {
  return (
    <Suspense fallback={<main className="page-center">Loading…</main>}>
      <SignInForm />
    </Suspense>
  );
}
